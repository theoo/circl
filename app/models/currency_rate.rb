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
