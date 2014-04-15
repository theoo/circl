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
# Table name: salaries_tax_data
#
# *id*::                      <tt>integer, not null, primary key</tt>
# *salary_id*::               <tt>integer, not null</tt>
# *tax_id*::                  <tt>integer, not null</tt>
# *position*::                <tt>integer, not null</tt>
# *employer_value_in_cents*:: <tt>integer, not null</tt>
# *employer_percent*::        <tt>decimal(6, 3), not null</tt>
# *employer_use_percent*::    <tt>boolean, not null</tt>
# *employee_value_in_cents*:: <tt>integer, not null</tt>
# *employee_percent*::        <tt>decimal(6, 3), not null</tt>
# *employee_use_percent*::    <tt>boolean, not null</tt>
# *created_at*::              <tt>datetime</tt>
# *updated_at*::              <tt>datetime</tt>
#--
# == Schema Information End
#++

class Salaries::TaxData < ActiveRecord::Base

  #################
  ### CALLBACKS ###
  #################

  before_save :compute

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  #################
  ### RELATIONS ###
  #################

  belongs_to :salary,
             :class_name => 'Salaries::Salary'
  belongs_to :tax,
             :class_name => 'Salaries::Tax'

  # money
  money :employer_value
  money :employee_value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :employee_percent, :if => :employee_use_percent
  validates_presence_of :employer_percent, :if => :employer_use_percent

  ########################
  ### INSTANCE METHODS ###
  ########################

  def title
    tax.title
  end

  def reference
    salary.reference.tax_data.where(:tax_id => tax.id).first
  end

  def children
    salary.children.map{ |s| s.tax_data.where(:tax_id => tax.id).first }
  end

  def is_reference?
    salary.is_reference?
  end

  def taxed_items
    tax.items.where(:salary_id => salary.id)
  end

  def reference_value
    Money.new(taxed_items.sum(:value_in_cents), salary.yearly_salary.currency)
  end

  def taxed_value
    tax.compute(reference_value, salary.year, salary.infos)[:taxed_value]
  end

  def compute_employer_value_from_percent
    self.employer_value = (reference_value * employer_percent) / 100.0
  end

  def compute_employer_percent_from_value
    if reference_value == 0
      self.employer_percent = 0
    else
      self.employer_percent = (employer_value / reference_value) * 100.0
    end
  end

  def compute_employer
    if employer_use_percent
      compute_employer_value_from_percent
    else
      compute_employer_percent_from_value
    end
  end

  def compute_employee_value_from_percent
    self.employee_value = reference_value * employee_percent / 100.0
  end

  def compute_employee_percent_from_value
    if reference_value == 0
      self.employee_percent = 0
    else
      self.employee_percent = (employee_value / reference_value) * 100.0
    end
  end

  def compute_employee
    if employee_use_percent
      compute_employee_value_from_percent
    else
      compute_employee_percent_from_value
    end
  end

  def compute
    compute_employer
    compute_employee
  end

  def reset
    h = tax.compute(reference_value, salary.year, salary.infos)
    self.employer_value          = h[:employer][:value]
    self.employer_percent        = h[:employer][:percent]
    self.employer_use_percent    = h[:employer][:use_percent]
    self.employee_value          = h[:employee][:value]
    self.employee_percent        = h[:employee][:percent]
    self.employee_use_percent    = h[:employee][:use_percent]
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:tax_title] = tax.title

    h[:reference_value] = reference_value.to_f
    h[:taxed_value] = taxed_value.to_f

    h[:employer_value] = employer_value.to_f
    h[:employee_value] = employee_value.to_f

    h[:errors] = errors
    h
  end

end
