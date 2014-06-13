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

class Invoice < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # Monetize deprecation warning
  require 'monetize/core_extensions'

  include ChangesTracker
  include StatusExtention
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  # Yes, it's bad to load helper in a model...
  class InvoiceHelper
    include ActionView::Helpers::DateHelper
  end

  def helper
    @h || InvoiceHelper.new
  end

  #################
  ### CALLBACKS ###
  #################

  before_save     :set_address_if_empty, :update_statuses
  after_save      :update_affair
  before_destroy  :check_presence_of_receipt
  after_destroy   :update_affair
  after_commit    :update_elasticsearch

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  belongs_to  :invoice_template
  has_many    :receipts, dependent: :destroy
  has_one     :owner, through: :affair
  has_one     :buyer, through: :affair
  has_one     :receiver, through: :affair
  has_many    :subscriptions, through: :affair, uniq: true
  has_many    :tasks,         through: :affair, uniq: true
  has_many    :product_items, through: :affair, uniq: true
  has_many    :extras,        through: :affair, uniq: true

  # paperclip
  has_attached_file :pdf

  # money
  money :value
  money :vat

  scope :open_invoices, Proc.new {
    mask = Invoice.statuses_value_for(:open)
    where("(invoices.status::bit(16) & ?::bit(16))::int = ? AND invoices.created_at < now()",
      mask, mask)
  }

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :invoice_template_id, :affair_id
  validates_presence_of :created_at, on: :update
  validates_with DateValidator, attribute: :created_at

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536
  validates_length_of :printed_address, maximum: 65536
  validates :value, presence: true,
                    numericality: { less_than_or_equal: 99999999.99 }, # BVR limit
                    allow_nil: true

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

  # Returns a hash of placeholders and values.
  def placeholders
    # internationlize dates
    I18n.locale = invoice_template.language.symbol

    h = {}
    # NOTE don't forget to add translation manualy. rake i18n:import_missing_translations won't parse this code.
    # NOTE Be careful with name colision, INVOICE_TITLE and INVOICE_TITLE_AND_SOMETHING won't work correctly.
    h[:simples] =   {
                      'LOCALE'                             => I18n.locale.to_s,
                      'INVOICE_ADDRESS'                    => simple_format(printed_address),
                      'INVOICE_DATE'                       => created_at.to_date.to_s,
                      'INVOICE_DAY_NUMERIC'                => I18n.l(created_at, format: "%d"),
                      'INVOICE_MONTH_NUMERIC'              => created_at.strftime("%m"),
                      'INVOICE_YEAR_NUMERIC'               => created_at.strftime("%Y"),
                      'INVOICE_DAY_WORD'                   => I18n.l(created_at, format: "%A"),
                      'INVOICE_MONTH_WORD'                 => I18n.l(created_at, format: "%B"),
                      'INVOICE_DESCRIPTION'                => description.to_s,
                      'INVOICE_ID'                         => id.to_s,
                      'INVOICE_TITLE'                      => title.to_s,
                      'INVOICE_VALUE_WITH_TAXES'           => value_with_taxes.to_doc,
                      'INVOICE_VALUE'                      => value.to_doc,
                      'INVOICE_VAT'                        => vat.to_doc,
                      'INVOICE_BALANCE_VALUE'              => balance_value.to_doc,
                      'INVOICE_RECEIPTS_VALUE'             => receipts_value.to_doc,
                      'INVOICE_OVERPAID_VALUE'             => overpaid_value.to_doc,
                      'INVOICE_OWNER_ID'                   => owner.id.to_s,
                      'INVOICE_OWNER_TITLE'                => owner.title.to_s,
                      'INVOICE_OWNER_NAME'                 => owner.name,
                      'INVOICE_OWNER_ORGANIZATION_NAME'    => owner.organization_name,
                      'INVOICE_OWNER_FIRST_NAME'           => owner.first_name,
                      'INVOICE_OWNER_LAST_NAME'            => owner.last_name,
                      'INVOICE_OWNER_FULL_NAME'            => owner.full_name,
                      'INVOICE_BUYER_ID'                   => buyer.id.to_s,
                      'INVOICE_BUYER_TITLE'                => buyer.title.to_s,
                      'INVOICE_BUYER_NAME'                 => buyer.name,
                      'INVOICE_BUYER_ORGANIZATION_NAME'    => buyer.organization_name,
                      'INVOICE_BUYER_FIRST_NAME'           => buyer.first_name,
                      'INVOICE_BUYER_LAST_NAME'            => buyer.last_name,
                      'INVOICE_BUYER_FULL_NAME'            => buyer.full_name,
                      'INVOICE_RECEIVER_ID'                => receiver.id.to_s,
                      'INVOICE_RECEIVER_TITLE'             => receiver.title.to_s,
                      'INVOICE_RECEIVER_NAME'              => receiver.name,
                      'INVOICE_RECEIVER_ORGANIZATION_NAME' => receiver.organization_name,
                      'INVOICE_RECEIVER_FIRST_NAME'        => receiver.first_name,
                      'INVOICE_RECEIVER_LAST_NAME'         => receiver.last_name,
                      'INVOICE_RECEIVER_FULL_NAME'         => receiver.full_name,
                      'AFFAIR_ID'                          => affair.id.to_s,
                      'AFFAIR_TITLE'                       => affair.title,
                      'AFFAIR_VALUE_WITH_TAXES'            => affair.value_with_taxes.to_doc,
                      'AFFAIR_VALUE'                       => affair.value.to_doc,
                      'AFFAIR_VAT_VALUE'                   => affair.vat_value.to_doc,
                      'AFFAIR_DESCRIPTION'                 => affair.description,
                      'AFFAIR_FOOTER'                      => affair.footer,
                      'AFFAIR_CONDITIONS'                  => affair.conditions,
                      'AFFAIR_SELLER_NAME'                 => affair.seller.try(:name)
                    }

    h[:iterators] = {
                      'EXTRAS'                            => extras,
                      'PRODUCT_ITEMS'                     => product_items,
                      'AFFAIR_RECEIPTS'                   => affair.receipts,
                      'RECEIPTS'                          => receipts,
                      'SUBSCRIPTIONS'                     => subscriptions,
                      'TASKS'                             => tasks
                    }

    # BVR stuff, if requested
    if invoice_template.with_bvr
      bvr_codelines = bvr_codeline(invoice_template.bvr_account).split('').map.with_index do |char, index|
        "<div class=\"char#{index + 1}\">#{char}</div>"
      end

      bvr_values = []
      if invoice_template.show_invoice_value
        bvr_values = value_in_cents.to_s.split('').reverse.map.with_index do |digit, index|
          "<div class=\"digit#{index + 1}\">#{digit}</div>"
        end
      end

      h[:simples].merge!({'BVR_REFERENCE_NUMBER'        => bvr_reference_number,
                          'BVR_SPACED_REFERENCE_NUMBER' => bvr_reference_number(with_spaces: true),
                          'BVR_ADDRESS'                 => invoice_template.bvr_address.to_s,
                          'BVR_ACCOUNT'                 => invoice_template.bvr_account.to_s,
                          'BVR_CODELINE'                => bvr_codelines.join,
                          'BVR_VALUE'                   => bvr_values.join })
    end

    h

  end

  # Returns the reference number for BVRs, the upper and shorter line.
  def bvr_reference_number(options = {})
    ref  = ApplicationSetting.value(:application_id).rjust(6, '0')  # application id
    ref += created_at.strftime('%d%m%y').rjust(6, '0')              # today's date
    ref += owner.id.to_s.rjust(6, '0')                              # owner id
    ref += id.to_s.rjust(6, '0')                                    # invoice id
    ref += '00'                                                     # digits available
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

    codeline  = '01'                                # type (01: CHF BVR)
    codeline += value_in_cents.to_s.rjust(10, '0')  # value
    codeline += codeline.to_i.mod10rec.to_s         # checksum
    codeline += '>'                                 # separator
    codeline += bvr_reference_number                # reference number
    codeline += '+'                                 # separator
    codeline += ' '                                 # space
    codeline += account_tokens.join                 # account
    codeline += '>'                                 # separator

    raise RuntimeError, "bvr_codeline error #{codeline.size} != 53" unless codeline.size == 53
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
    helper.distance_of_time_in_words_to_now(created_at)
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
    return false unless pdf_updated_at

    # Check if pdf requires an update because invoice is newer
    return false if updated_at > pdf_updated_at.to_datetime

    # Check if pdf requires an update because its template is newer
    invoice_template.updated_at < pdf_updated_at.to_datetime
  end

  # Append a background task in the queue to update the PDF.
  def update_pdf
    BackgroundTasks::GenerateInvoicePdf.schedule(invoice_id: self.id)
  end

  # Run immediately a background task to update the PDF.
  def update_pdf!
    BackgroundTasks::GenerateInvoicePdf.process!(invoice_id: self.id)
  end

  # Placeholder proxy
  def affair_receipts
    affair.receipts
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
    if cancelled
      statuses << :cancelled if cancelled
    else
      statuses << :open if open?
      statuses << :underpaid if underpaid?
    end

    # Paid or overpaid
    # TODO How an invoice could be paid and open in the same time ?
    if offered
      statuses << :offered if offered
    else
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
  def update_elasticsearch
    owner.update_index unless tracked_changes.empty?
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

end
