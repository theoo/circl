# == Schema Information
#
# Table name: receipts
#
#  id               :integer          not null, primary key
#  invoice_id       :integer
#  value_in_cents   :integer
#  value_currency   :string(255)
#  value_date       :date
#  means_of_payment :string(255)      default("")
#  created_at       :datetime
#  updated_at       :datetime
#

class Receipt < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # Monetize deprecation warning
  require 'monetize/core_extensions'

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  after_save    :update_invoice
  after_destroy :update_invoice

  after_commit :update_people_in_search_engine

  #################
  ### RELATIONS ###
  #################

  belongs_to :invoice

  has_one :affair,
          through: :invoice

  has_one :owner,
          through: :affair

  has_one :buyer,
          through: :affair

  has_one :receiver,
          through: :affair

  has_many :subscriptions,
          -> { distinct },
          through: :affair

  # money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :value_date, :invoice_id
  validates_with Validators::Date, attribute: :value_date
  validates :value, presence: true,
    numericality: { more_than_or_equal: -99999999.99, less_than_or_equal: 99999999.99 } # BVR limit


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

  # FIXME Why this?
  def update_people_in_search_engine
    owner.update_search_engine unless self.changes.empty?
  end

end
