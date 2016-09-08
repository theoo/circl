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

class Currency < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_destroy :ensure_currency_is_not_used
  before_save :ensure_currency_is_not_used
  before_save :default_values
  after_save :create_currencies_conversion_items
  after_destroy :remove_currencies_conversion_items

  #################
  ### RELATIONS ###
  #################

  has_many :rates_as_base, # buy
    class_name: 'CurrencyRate',
    foreign_key: 'from_currency_id'

  has_many :rates_as_exchange, # sell
    class_name: 'CurrencyRate',
    foreign_key: 'to_currency_id'

  ###################
  ### VALIDATIONS ###
  ###################

  validates :iso_code, presence: true, length: {is: 3}
  validates :iso_numeric, length: {maximum: 255}
  validates :name, length: {maximum: 255}
  validates :symbol, length: {maximum: 3}
  validates :subunit, length: {maximum: 255}
  validates :separator, length: {maximum: 255}
  validates :delimiter, length: {maximum: 255}

  validates :priority, numericality: true, unless: Proc.new {|c| c.priority.blank? }
  validates :subunit_to_unit, numericality: true, unless: Proc.new {|c| c.subunit_to_unit.blank? }

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:errors]         = errors

    h
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  private

  def default_values
    self.priority         ||= Currency.count > 0 ? Currency.order(:priority).last.priority + 1 : 1
    self.subunit          ||= "cent"
    self.subunit_to_unit  ||= 100
    self.separator        ||= ","
    self.delimiter        ||= "."
  end

  def create_currencies_conversion_items
    Currency.all.each do |c|
      next if id == c.id

      if CurrencyRate.where(from_currency_id: id, to_currency_id: c.id).count == 0
        CurrencyRate.create!(from_currency_id: id, to_currency_id: c.id, rate: 1)
      end

      if CurrencyRate.where(from_currency_id: c.id, to_currency_id: id).count == 0
        CurrencyRate.create!(from_currency_id: c.id, to_currency_id: id, rate: 1)
      end
    end
  end

  def remove_currencies_conversion_items
    Currency.all.each do |c|
      next if id == c.id
      CurrencyRate.where(from_currency_id: id, to_currency_id: c.id).each(&:destroy)
      CurrencyRate.where(from_currency_id: c.id, to_currency_id: id).each(&:destroy)
    end
  end

  def ensure_currency_is_not_used

    # If there is another currency with the same iso_code, validates
    return true if Currency.where(iso_code: iso_code).where.not(id: id).count > 0

    count = 0
    count += Affair.where(value_currency: iso_code).count
    count += Extra.where(value_currency: iso_code).count
    count += Extra.where(vat_currency: iso_code).count
    count += Invoice.where(value_currency: iso_code).count
    count += Invoice.where(vat_currency: iso_code).count
    count += ProductVariant.where(buying_price_currency: iso_code).count
    count += ProductVariant.where(selling_price_currency: iso_code).count
    count += ProductVariant.where(art_currency: iso_code).count
    count += ProductVariant.where(vat_currency: iso_code).count
    count += Receipt.where(value_currency: iso_code).count
    count += Salaries::Salary.where(yearly_salary_currency: iso_code).count
    count += Salaries::Salary.where(cert_food_currency: iso_code).count
    count += Salaries::Salary.where(cert_transport_currency: iso_code).count
    count += Salaries::Salary.where(cert_food_currency: iso_code).count
    count += Salaries::Salary.where(cert_logding_currency: iso_code).count
    count += Salaries::Salary.where(cert_misc_salary_car_currency: iso_code).count
    count += Salaries::Salary.where(cert_misc_salary_other_value_currency: iso_code).count
    count += Salaries::Salary.where(cert_non_periodic_value_currency: iso_code).count
    count += Salaries::Salary.where(cert_capital_value_currency: iso_code).count
    count += Salaries::Salary.where(cert_participation_currency: iso_code).count
    count += Salaries::Salary.where(cert_compentation_admin_members_currency: iso_code).count
    count += Salaries::Salary.where(cert_misc_other_value_currency: iso_code).count
    count += Salaries::Salary.where(cert_avs_ac_aanp_currency: iso_code).count
    count += Salaries::Salary.where(cert_lpp_currency: iso_code).count
    count += Salaries::Salary.where(cert_buy_lpp_currency: iso_code).count
    count += Salaries::Salary.where(cert_is_currency: iso_code).count
    count += Salaries::Salary.where(cert_alloc_traveling_currency: iso_code).count
    count += Salaries::Salary.where(cert_alloc_food_currency: iso_code).count
    count += Salaries::Salary.where(cert_alloc_other_actual_cost_value_currency: iso_code).count
    count += Salaries::Salary.where(cert_alloc_representation_currency: iso_code).count
    count += Salaries::Salary.where(cert_alloc_car_currency: iso_code).count
    count += Salaries::Salary.where(cert_alloc_other_fixed_fees_value_currency: iso_code).count
    count += Salaries::Salary.where(cert_formation_currency: iso_code).count
    count += Salaries::TaxData.where(employer_value_currency: iso_code).count
    count += Salaries::TaxData.where(employee_value_currency: iso_code).count
    count += Salaries::Item.where(value_currency: iso_code).count
    count += Salaries::Taxes::Generic.where(salary_from_currency: iso_code).count
    count += Salaries::Taxes::Generic.where(salary_to_currency: iso_code).count
    count += Salaries::Taxes::Generic.where(employer_value_currency: iso_code).count
    count += Salaries::Taxes::Generic.where(employee_value_currency: iso_code).count
    count += Salaries::Taxes::Is.where(yearly_from_currency: iso_code).count
    count += Salaries::Taxes::Is.where(yearly_to_currency: iso_code).count
    count += Salaries::Taxes::Is.where(monthly_from_currency: iso_code).count
    count += Salaries::Taxes::Is.where(monthly_to_currency: iso_code).count
    count += Salaries::Taxes::Is.where(hourly_from_currency: iso_code).count
    count += Salaries::Taxes::Is.where(hourly_to_currency: iso_code).count
    count += Task.where(value_currency: iso_code).count
    count += TaskRate.where(value_currency: iso_code).count
    count += TaskType.where(value_currency: iso_code).count

    if count > 0
      errors.add(:base,
        I18n.t('currency.errors.unable_to_destroy_a_currency_which_is_used'))
      false
    end
  end

end
