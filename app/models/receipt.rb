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
# Table name: receipts
#
# *id*::               <tt>integer, not null, primary key</tt>
# *invoice_id*::       <tt>integer</tt>
# *value_in_cents*::   <tt>integer</tt>
# *value_currency*::   <tt>string(255)</tt>
# *value_date*::       <tt>date</tt>
# *means_of_payment*:: <tt>string(255), default("")</tt>
# *created_at*::       <tt>datetime</tt>
# *updated_at*::       <tt>datetime</tt>
#--
# == Schema Information End
#++

class Receipt < ActiveRecord::Base

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

  after_save    :update_invoice
  after_destroy :update_invoice

  after_commit :update_elasticsearch

  #################
  ### RELATIONS ###
  #################

  belongs_to :invoice

  has_one :affair, through: :invoice
  has_one :owner, through: :affair
  has_one :buyer, through: :affair
  has_one :receiver, through: :affair
  has_many :subscriptions, through: :affair, uniq: true

  # money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :value_date, :invoice_id
  validates_with DateValidator, attribute: :value_date
  validates :value, presence: true,
                    numericality: { greater_than: 0,
                                       less_than_or_equal: 99999999.99 } # BVR limit


  # Validate fields of type 'string' length
  validates_length_of :means_of_payment, maximum: 255

  #####################
  ### CLASS METHODS ###
  #####################

  def self.orphans
    where(invoice_id: nil)
  end

  # Complicated method to extract overpaid value of the last receipts, if existing
  def overpaid_value
    if invoice.overpaid_value > 0
      receipts = invoice.receipts.order(:value_date, :id)
      paying_receipts = []

      sum = 0.to_money
      receipts.each do |r|
        if sum < invoice.value
          paying_receipts << r
          sum += r.value
        else
          break
        end
      end

      if paying_receipts.index(self)
        return sum - invoice.value if paying_receipts.last == self
      else
        return self.value
      end
    end

    0.to_money
  end

  # Used when generating pdf (odt/serenity)
  def first_payment?
    invoice.receipts.order(:value_date, :id).first == self
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)

    # add relation description to save a request
    h[:invoice_id]     = invoice_id
    h[:invoice_value]  = invoice.try(:value).try(:to_f)
    h[:invoice_title]  = invoice.try(:title)

    h[:affair_id]      = invoice.try(:affair_id)
    h[:affair_title]   = invoice.try(:affair).try(:title)

    h[:owner_id]       = invoice.try(:owner).try(:id)
    h[:owner_name]     = invoice.try(:owner).try(:name)

    h[:value]          = value.try(:to_f)
    h[:overpaid_value] = overpaid_value.try(:to_f)

    h[:errors]         = errors
    h
  end

  protected

  # on destroy, re/open invoice
  def update_invoice
    invoice.save # run callbacks
    true
  end

  private

  def update_elasticsearch
    owner.update_index unless self.changes.empty?
  end

end
