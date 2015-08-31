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

class Creditor < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # Monetize deprecation warning
  require 'monetize/core_extensions'

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  include VatExtension
  extend  MoneyComposer

  # Used for import
  attr_accessor :notices

  after_initialize do
    @notices = ActiveModel::Errors.new(self)
  end

  #################
  ### CALLBACKS ###
  #################

  before_save do
    if custom_value_with_taxes
      original_value = value
      self.value = reverse_vat(original_value)
      self.vat = original_value - value
    end

    self.discount_percentage ||= 0
    self.account ||= creditor.creditor_account
    self.transitional_account ||= creditor.creditor_transitional_account
  end

  #################
  ### RELATIONS ###
  #################

  # Names should be reported in status and vice-versa
  scope :paid, -> { where("creditors.paid_on is not null") }
  scope :unpaid, -> { where(paid_on: nil) }
  scope :late, -> { unpaid.where("creditors.invoice_ends_on < ?", Time.now) }
  scope :invoices_to_record_in_books, -> {
    where("creditors.invoice_received_on is not null and creditors.invoice_in_books_on is null")
  }
  scope :payments_to_record_in_books, -> {
    where("creditors.paid_on is not null and creditors.payment_in_books_on is null")
  }

  has_one :creditor,
          class_name: 'Person',
          primary_key: 'creditor_id',
          foreign_key: 'id'

  # relation not reflected on affairs model
  has_one :affair,
          primary_key: 'affair_id',
          foreign_key: 'id'

  # Money
  money :value
  money :vat

  attr_accessor :custom_value_with_taxes
  attr_accessor :template

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :creditor_id, :invoice_received_on, :invoice_ends_on, :value_in_cents, :value_currency

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536

  validate :discount_ends_before_invoice

  ########################
  #### CLASS METHODS #####
  ########################

  class << self
    # Returns status hash with machine alias and human translation
    def statuses
      # Names should be reported in scopes and vice-versa
      {
        paid: I18n.t("creditor.status.paid"),
        unpaid: I18n.t("creditor.status.unpaid"),
        late: I18n.t("creditor.status.late"),
        invoices_to_record_in_books: I18n.t("creditor.status.invoices_to_record_in_books"),
        payments_to_record_in_books: I18n.t("creditor.status.payments_to_record_in_books")
      }
    end

    # Returns date fields with a translation
    def date_fields
      {
        created_at: I18n.t("creditor.date_fields.creation"),
        invoice_received_on: I18n.t("creditor.date_fields.reception"),
        invoice_ends_on: I18n.t("creditor.date_fields.invoice_end"),
        invoice_in_books_on: I18n.t("creditor.date_fields.invoice_books_recording"),
        discount_ends_on: I18n.t("creditor.date_fields.discount_end"),
        paid_on: I18n.t("creditor.date_fields.payment_date"),
        payment_in_books_on: I18n.t("creditor.date_fields.payment_books_recording"),
      }
    end

    def parse_csv(file, lines = [], skip_columns = [], do_record = false)
      creditors = []
      # in case argument nil is sent
      lines ||= []
      skip_columns ||= []

      # Expected file structure
      columns_list = [
        :creditor_id,
        :provider_name,
        :value,
        :discount_percentage,
        :transitional_account,
        :account,
        :invoice_received_on,
        :invoice_ends_on,
        :title,
        :affair_id,
        :invoice_in_books_on,
        :paid_on,
        :payment_in_books_on ]

      begin
        Creditor.transaction do

          csvStruct = Struct.send(:new, *columns_list)

          CSV.parse(file, encoding: 'UTF-8')[1..-1].each_with_index do |row, row_index|
            next if lines.size > 0 and ! lines.index((row_index + 1).to_s)

            row.map!{ |s| (s || '').force_encoding('utf-8').strip }

            c = csvStruct.new(*row)

            if row.size != columns_list.size
              creditors << "#{I18n.t('creditor.errors.line')} #{i+2}: #{I18n.t('creditor.errors.invalid_line')}"
              next
            end

            params = c.to_h
            params.delete(:provider_name) # Just for the view
            params[:custom_value_with_taxes] = true
            creditor = Creditor.create!(params) # trig validation
            raise ActiveRecord::Rollback unless creditor.creditor

            creditors << creditor
          end # csv

          raise ActiveRecord::Rollback unless do_record

        end # transaction

      rescue ActiveRecord::Rollback
        # continue

      rescue Exception => e
        creditors = I18n.t("creditor.errors.unable_to_parse_file") + " (" + e.inspect + ")"
      end # transaction

      [creditors, columns_list]
    end

  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  def late?
    return false if invoice_ends_on.nil?
    paid_on.nil? and invoice_ends_on < Time.now
  end

  def discount_late?
    return false if discount_ends_on.nil?
    paid_on.nil? and discount_ends_on < Time.now
  end

  def discount_paid_ontime?
    return false if discount_ends_on.nil? or paid_on.nil?
    discount_ends_on <= paid_on
  end

  def paid?
    !paid_on.nil?
  end

  def value_with_taxes
    value + vat
  end

  def discount_value(v = value_with_taxes)
    if discount_percentage and paid_on or (not discount_ends_on.nil? and Time.now < discount_ends_on)
      (v / 100.0 * discount_percentage)
    else
      0
    end
  end

  def value_with_discount(v = value_with_taxes)
    v - discount_value(v)
  end

  def discount_ends_before_invoice
    if invoice_ends_on and discount_ends_on and invoice_ends_on < discount_ends_on
      errors.add(:discount_ends_on, I18n.t("creditor.errors.discount_cannot_end_after_invoice_end"))
      false
    end
  end

  def as_json(options = nil)
    h = super(options)
    h[:creditor_name]    = creditor.try(:name)
    h[:affair_name]      = affair.try(:title)
    h[:value]            = value.try(:to_f)
    h[:value_currency]   = value.currency.try(:iso_code)
    h[:vat]              = vat.try(:to_f)
    h[:vat_currency]     = vat.currency.try(:iso_code)
    h[:value_with_taxes] = value_with_taxes.try(:to_f)
    h
  end

end
