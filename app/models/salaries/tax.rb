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
# Table name: salaries_taxes
#
# *id*::                 <tt>integer, not null, primary key</tt>
# *title*::              <tt>string(255), not null</tt>
# *model*::              <tt>string(255), not null</tt>
# *created_at*::         <tt>datetime</tt>
# *updated_at*::         <tt>datetime</tt>
# *employee_account*::   <tt>string(255)</tt>
# *exporter_avs_group*:: <tt>boolean, default(FALSE), not null</tt>
# *exporter_lpp_group*:: <tt>boolean, default(FALSE), not null</tt>
# *exporter_is_group*::  <tt>boolean, default(FALSE), not null</tt>
# *employer_account*::   <tt>string(255), default("")</tt>
#--
# == Schema Information End
#++

class Salaries::Tax < ActiveRecord::Base

  ################
  ### CALLBACKS ##
  ################

  before_destroy :prevent_destroy_if_used

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing

  #################
  ### VALIDATIONS #
  #################

  validates_presence_of :title
  validates_length_of :title, :maximum => 255

  #################
  ### RELATIONS ###
  #################

  monitored_habtm :items,
                  :class_name => 'Salaries::Item',
                  :join_table => 'salaries_items_taxes',
                  :order => :position
  has_many :tax_data,
           :class_name => 'Salaries::TaxData'

  has_many :generic_taxes,
           :class_name => 'Salaries::Taxes::Generic'
  has_many :age_taxes,
           :class_name => 'Salaries::Taxes::Age'
  has_many :is_taxes,
           :class_name => 'Salaries::Taxes::Is'


  ########################
  ### INSTANCE METHODS ###
  ########################

  def compute(reference_value, year, infos)
    model.constantize.compute(reference_value, year, infos, self)
  end

  def process_data(data)
    model.constantize.process_data(self, data)
  end

  def copy_year_data(from, to)
    model.constantize.where(:year => from).each do |item|
      new_item = item.dup
      new_item.year = to
      new_item.save!
    end
  end

  def number_of_rows
    model.constantize.where(:tax_id => self.id).count
  end

  def available_years
    model.constantize.where(:tax_id => self.id).select("DISTINCT year").map(&:year)
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:title] = title
    h[:model] = model
    h[:employee_account] = employee_account
    h[:employer_account] = employer_account
    h[:number_of_rows]   = number_of_rows
    h[:available_years]  = available_years.join(", ")

    h[:errors] = errors
    h
  end

  private

  def prevent_destroy_if_used
    if tax_data.size > 0
      errors.add(:base,
                 I18n.t('tax.errors.unable_to_destroy_a_tax_which_is_used'))
      false
    end
  end

end
