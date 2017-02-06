class CurrencyRate < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################


  #################
  ### RELATIONS ###
  #################

  before_destroy :ensure_no_currency_depend_on_it
  belongs_to :from_currency, class_name: 'Currency'
  belongs_to :to_currency, class_name: 'Currency'

  ###################
  ### VALIDATIONS ###
  ###################

  validates :from_currency_id, presence: true
  validates :to_currency_id, presence: true
  validates :rate, presence: true, numericality: {greater_than: 0}

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:from_currency_iso_code] = from_currency.try(:iso_code)
    h[:to_currency_iso_code] = to_currency.try(:iso_code)
    h[:errors] = errors

    h
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  private

  def ensure_no_currency_depend_on_it
    if from_currency and to_currency
      errors.add(:base,
        I18n.t('currency.errors.unable_to_destroy_a_rate_which_is_used'))
      false
    end
  end

end
