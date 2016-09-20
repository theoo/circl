=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

# == Schema Information
#
# Table name: invoices
#
# *id*::                  <tt>integer, not null, primary key</tt>
# *title*::               <tt>string(255), default("")</tt>
# *description*::         <tt>text, default("")</tt>
# *value_in_cents*::      <tt>integer, not null</tt>
# *value_currency*::      <tt>string(255)</tt>
# *cancelled*::           <tt>boolean, default(FALSE), not null</tt>
# *offered*::             <tt>boolean, default(FALSE), not null</tt>
# *created_at*::          <tt>datetime</tt>
# *updated_at*::          <tt>datetime</tt>
# *affair_id*::           <tt>integer</tt>
# *printed_address*::     <tt>text, default("")</tt>
# *invoice_template_id*:: <tt>integer, not null</tt>
# *pdf_file_name*::       <tt>string(255)</tt>
# *pdf_content_type*::    <tt>string(255)</tt>
# *pdf_file_size*::       <tt>integer</tt>
# *pdf_updated_at*::      <tt>datetime</tt>
#--
# == Schema Information End
#++

class Invoice < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # Monetize deprecation warning
  require 'monetize/core_extensions'

  # include ChangesTracker
  include StatusExtension
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  include VatExtension
  extend  MoneyComposer

  # TODO: Move this to jsbuilder
  # Yes, it's bad to load view helper in a model...
  class InvoiceHelper
    include ActionView::Helpers::DateHelper
  end

  def helper
    @h || InvoiceHelper.new
  end

  #################
  ### CALLBACKS ###
  #################

  before_save     :set_address_if_empty, :update_statuses, :set_vat_percentage_if_empty
  before_save     :compute_value_without_taxes, if: 'custom_value_with_taxes'
  after_save      :update_affair
  before_destroy  :check_presence_of_receipt
  after_destroy   :update_affair
  after_commit    :update_people_in_search_engine

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair

  belongs_to  :invoice_template

  belongs_to  :condition,
              class_name: 'AffairsCondition'

  has_many    :receipts,
              dependent: :destroy

  has_one     :owner,
              through: :affair

  has_one     :buyer,
              through: :affair

  has_one     :receiver,
              through: :affair

  has_many    :subscriptions,
              -> { distinct },
               through: :affair

  has_many    :tasks,
              -> { distinct },
               through: :affair

  has_many    :product_items,
              -> { distinct },
               through: :affair

  has_many    :extras,
              -> { distinct },
               through: :affair

  # paperclip
  has_attached_file :pdf

  # money
  money :value
  money :vat

  # FIXME open is a private method from ActiveRecord, do not override it (change name)
  scope :open, -> {
    mask = Invoice.statuses_value_for(:open)
    where("(invoices.status::bit(16) & ?::bit(16))::int = ? AND invoices.created_at < now()", mask, mask)
  }

  scope :billable, -> { where("cancelled = ? AND offered = ?", false, false) }
  scope :unbillable, -> { where("cancelled = ? OR offered = ?", true, true) }

  alias_method :template, :invoice_template
  attr_accessor :custom_value_with_taxes

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :invoice_template_id, :affair_id
  validates_presence_of :created_at, on: :update
  validates_with Validators::Date, attribute: :created_at

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536
  validates_length_of :printed_address, maximum: 65536
  validates :value, presence: true,
                    numericality: { less_than_or_equal: 99999999.99 }, # BVR limit
                    allow_nil: true

  # Mime type or content type validation sometime fails with the current script.
  # Whether update the script or add "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" content type
  # which seams to be the most frequent source of confusion.
  validates_attachment_content_type :pdf, :content_type => /\A.*\Z/ # Fake validator
  # validates_attachment :pdf,
  #   content_type: { content_type: "application/pdf" }

  validate :prevent_title_change, if: 'title_changed?'

  #####################
  ### CLASS METHODS ###
  #####################

  # Parses and input bvr reference number as a string and
  # extract revelent information.
  # Returns a hash with corresponding values.
  # DOC describe the hash
  def self.parse_bvr_reference_number(str)
    # Sanitize input
    str = str.to_s.delete(' ')

    # Match
    matches = str.match(/^(\d{6})(\d{6})(\d{6})(\d{6})(\d{2})(\d)$/)
    return nil unless matches

    hash = {}
    hash[:application_id]     = matches.captures[0].to_i
    hash[:invoice_date]       = Date.strptime(matches.captures[1], '%d%m%y') rescue nil
    hash[:owner_id]           = matches.captures[2].to_i
    hash[:invoice_id]         = matches.captures[3].to_i
    hash[:digits_available]   = matches.captures[4].to_i
    hash[:modulo]             = matches.captures[5].to_i
    hash[:valid]              = (str[0..-2].to_i.mod10rec == hash[:modulo])
    hash
  end

  # Returns the list of available statuses as an array.
  # Watch the sources to read available statuses.
  def self.available_statuses
    # i18n-tasks-use I18n.t("invoice.views.statuses.open")
    # i18n-tasks-use I18n.t("invoice.views.statuses.underpaid")
    # i18n-tasks-use I18n.t("invoice.views.statuses.cancelled")
    # i18n-tasks-use I18n.t("invoice.views.statuses.paid")
    # i18n-tasks-use I18n.t("invoice.views.statuses.overpaid")
    # i18n-tasks-use I18n.t("invoice.views.statuses.offered")

    [
                 # under bit weight 256 (bits 0-7),
                 # invoice is not (fully) paid
     :open,      # 0
     :underpaid, # 1
     nil,        # 2
     nil,        # 3
     nil,        # 4
     nil,        # 5
     nil,        # 6
     :cancelled, # 7

                 # starting from 256 (bit 8-15),
                 # invoice is paid
     :paid,      # 8
     :overpaid,  # 9
     nil,        # 10
     nil,        # 11
     nil,        # 12
     nil,        # 13
     nil,        # 14
     :offered    # 15
    ]
  end


  ########################
  ### INSTANCE METHODS ###
  ########################

  # Returns the reference number for BVRs, the upper and shorter line.
  def bvr_reference_number(options = {})
    if invoice_template.account_identification.blank?
      ref = ApplicationSetting.value(:application_id).to_s.rjust(6, '0') # application id
    else
      ref = invoice_template.account_identification
    end

    ref += created_at.strftime('%d%m%y').rjust(6, '0')              # today's date
    ref += owner.id.to_s.rjust(6, '0')                              # owner id
    ref += id.to_s.rjust(6, '0')                                    # invoice id
    ref += '00'                                                     # available digits
    ref += ref.to_i.mod10rec.to_s                                   # checksum

    raise RuntimeError, "bvr_ref error #{ref.size} != 27" unless ref.size == 27

    if options[:with_spaces]
      (0..4).each do |i|
        ref.insert((i * 6) + 2, ' ')
      end
    end

    ref
  end

  # Returns the correct codeline for BVRs, the long bottom line.
  def bvr_codeline(bvr_account)
    # Do not go any further if template doesn't print BVR
    return unless invoice_template.with_bvr

    account_tokens = bvr_account.split('-')
    account_tokens[0] = account_tokens[0].rjust(2, '0')
    account_tokens[1] = account_tokens[1].rjust(6, '0')

    codeline = ""

    if value > 0 and template.show_invoice_value
      codeline += '01'                                        # type (01: CHF BVR)
      codeline += value_with_taxes.cents.to_s.rjust(10, '0')  # value
      codeline += codeline.to_i.mod10rec.to_s                 # checksum
    else
      codeline += '          042'                             # type (042: ??) # TODO doc
    end

    codeline += '>'                                         # separator
    codeline += bvr_reference_number                        # reference number
    codeline += '+'                                         # separator
    codeline += ' '                                         # space
    codeline += account_tokens.join                         # account
    codeline += '>'                                         # separator

    unless [43, 53].include? codeline.size
      raise RuntimeError, "bvr_codeline lenght error #{codeline.size}. Allowed: 43, 53"
    end
    codeline
  end

  # Returns receipt values sum
  def receipts_value
    receipts.map(&:value).sum.to_money
  end

  # Returns the balance of receipts sum and invoice value.
  # Zero (0) equals a perfect balance when the invoice is paid and
  # there is no overpaying.
  def balance_value
    receipts_value - value_with_taxes
  end

  # Returns the overpaid value.
  def overpaid_value
    (balance_value > 0) ? balance_value : 0.to_money
  end

  def value_with_taxes
    value + vat
  end

  def compute_vat
    return 0.to_money unless ApplicationSetting.value('use_vat')
    value * (100.0 / vat_percentage)
  end

  # Returns true if receipts sum is greater or equal ot invoice value.
  def paid?
    return false if receipts.size == 0
    balance_value >= 0
  end

  # Returns true if receipts sum is greater than invoice value.
  def overpaid?
    balance_value > 0
  end

  # Returns true if it has receipts but receipts sum is lower than invoice value.
  def underpaid?
    balance_value < 0 and receipts_value > 0
  end

  # Returns true if receipts value is lower than invoice value, no matter if
  # payment has been done or not.
  def open?
    return true if receipts.size == 0
    balance_value < 0
  end

  def translated_statuses
    get_statuses.map{|s| I18n.t("invoice.views.statuses." + s.to_s)}.join(", ")
  end

  def translated_age
    helper.distance_of_time_in_words_to_now(created_at, highest_measure_only: true, vague: true)
  end

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    # add relation description to save a request
    h[:owner_id]         = owner.try(:id)
    h[:owner_name]       = owner.try(:name)
    h[:buyer_id]         = buyer.try(:id)
    h[:buyer_name]       = buyer.try(:name)
    h[:receiver_id]      = receiver.try(:id)
    h[:receiver_name]    = receiver.try(:name)
    h[:affair_title]     = affair.try(:title)

    h[:value]            = value.try(:to_f)
    h[:vat]              = vat.try(:to_f)
    h[:value_with_taxes] = value_with_taxes.try(:to_f)
    h[:created_at]       = created_at.to_date
    h[:age]              = translated_age

    h[:receipts_value]   = receipts_value.try(:to_f)
    h[:balance_value]    = balance_value.try(:to_f)

    h[:statuses]         = translated_statuses

    h[:errors]           = errors

    h
  end

  # Checks if pdf is up to date.
  def pdf_up_to_date?
    return false unless pdf?

    return false unless pdf_updated_at

    # Check if pdf requires an update because invoice is newer
    return false if updated_at > pdf_updated_at.to_datetime

    # Check if pdf requires an update because its template is newer
    return false if invoice_template.updated_at > pdf_updated_at.to_datetime

    # Check if its affair is newer
    return false if affair.updated_at > pdf_updated_at.to_datetime

    # Check if its receipts list has changed
    if receipts.count > 0
      return false if receipts.order(:updated_at).last.updated_at > pdf_updated_at.to_datetime
    end

    true
  end

  #
  # Generate the PDF in a background task
  #
  # @return [String] Resque::Plugins::Status job id (UUID)
  def update_pdf
    Invoices::PdfJob.perform_later invoice_id: self.id
  end

  #
  # Generate the PDF right away
  #
  # @return [boolean] true if it succeed
  def update_pdf!
    Invoices::PdfJob.perform_now(invoice_id: self.id)
  end

  # Placeholder proxy
  def affair_receipts
    affair.receipts
  end

  # TODO SQL
  def parent_invoices_from_subscriptions
    parent_affairs = subscriptions.map{|s| s.parents.map{|sub| sub.affairs.where(owner: owner)} }.flatten
    parent_affairs.map{|a| a.invoices }.flatten.sort_by(&:created_at)
  end

  # TODO SQL
  def parent_invoices_from_affairs
    parent_affairs = affair.parents
    parent_affairs.map{|a| a.invoices }.flatten.sort_by(&:created_at)
  end

  protected

  # Abort destroy if receipt is present.
  def check_presence_of_receipt
    unless receipts.empty?
      errors.add(:base,
        I18n.t('invoice.errors.cant_destroy_if_existing_receipt'))
      false
    end
  end

  private

  # State machine
  def update_statuses
    statuses = []
    # Underpaid
    if cancelled or offered
      statuses << :cancelled if cancelled
      statuses << :offered if offered
    else
      statuses << :open if open?
      statuses << :underpaid if underpaid?

      statuses << :paid if paid?
      statuses << :overpaid if overpaid?
    end

    self.reset_statuses(statuses)
  end

  def update_affair
    # Check affair existence so it's possible to destroy an orphan invoice.
    # (Migration 20130712160745_update_invoices_and_affairs_status.rb)
    # Saving affair will run callbacks and update statuses.
    affair.save if affair
    true
  end

  # Updates the search engine
  # FIXME Why this ?
  def update_people_in_search_engine
    owner.update_search_engine unless self.changes.empty?
  end

  # Callback method to reset printed_address field if empty.
  def set_address_if_empty
    # buyer address
    if self.printed_address.blank?
      # Check buyer existence so it's possible to destroy an orphan invoice.
      # (Migration 20130712160745_update_invoices_and_affairs_status.rb)
      self.printed_address = self.buyer.address_for_bvr if self.buyer
    end
  end

  def set_vat_percentage_if_empty
    unless self.vat_percentage
      self.vat_percentage ||= affair.vat_percentage
      self.vat_percentage = ApplicationSetting.value('service_vat_rate')
    end
  end

  def compute_value_without_taxes
    total = value
    self.value = reverse_vat(value)
    self.vat = total - self.value
  end

  def vat_calculation_availability
    extras.each do |i|
      if i.vat_percentage != ApplicationSetting.value("service_vat_rate")
        errors.add(:base,
           I18n.t('affair.errors.unable_to_compute_value_without_taxes_if_extras_have_different_vat_values'))
        return false
      end
    end
  end

  def prevent_title_change
    if subscriptions.count > 0 and subscriptions.first.title != title
      errors.add(:title, I18n.t('affair.errors.cant_update_title_if_it_has_subscriptions'))
      false
    end
  end

end
