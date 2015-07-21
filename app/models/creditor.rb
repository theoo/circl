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
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  # before_save :update_value, if: 'value_in_cents.blank?'
  # before_save :update_vat, if: 'vat_in_cents.blank?'
  # before_save :set_vat_percentage, if: 'vat_percentage.blank?'

  #################
  ### RELATIONS ###
  #################

  has_one :creditor,
          class_name: 'Person',
          primary_key: 'creditor_id',
          foreign_key: 'id'

  # relation not reflected on affairs model
  has_one :affair

  # Money
  money :value
  money :vat

  scope :paid, -> { where("creditors.paid_on is not null") }
  scope :unpaid, -> { where(paid_on: nil) }
  scope :late, -> { where("creditors.invoice_ends_on < ?", Time.now) }
  scope :invoices_to_record_in_books, -> {
    where("creditors.invoice_received_on is not null and creditors.invoice_in_books_on is null")
  }
  scope :payments_to_record_in_books, -> {
    where("creditors.paid_on is not null and creditors.payment_in_books_on is null")
  }

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

  def paid?
    !paid_on.nil?
  end

  def value_with_taxes
    value + vat
  end

  def discount_ends_before_invoice
    if invoice_ends_on and discount_ends_on and invoice_ends_on < discount_ends_on
      error.add(:discount_ends_on, I18n.t("creditor.errors.discount_cannot_end_after_invoice_end"))
      false
    end
  end

  def as_json(options = nil)
    h = super(options)
    h[:value]            = value.try(:to_f)
    h[:value_currency]   = value.currency.try(:iso_code)
    h[:value_with_taxes] = value_with_taxes.try(:to_f)
    h
  end

end
