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
# Table name: salaries_taxes_age
#
# *id*::               <tt>integer, not null, primary key</tt>
# *tax_id*::           <tt>integer, not null</tt>
# *year*::             <tt>integer, not null</tt>
# *men_from*::         <tt>integer, not null</tt>
# *men_to*::           <tt>integer, not null</tt>
# *women_from*::       <tt>integer, not null</tt>
# *women_to*::         <tt>integer, not null</tt>
# *employer_percent*:: <tt>decimal(6, 3), not null</tt>
# *employee_percent*:: <tt>decimal(6, 3), not null</tt>
# *created_at*::       <tt>datetime</tt>
# *updated_at*::       <tt>datetime</tt>
#--
# == Schema Information End
#++




# TODO refactor this into a polymorphic association
class Salaries::Taxes::Age < ApplicationRecord

  self.table_name = :salaries_taxes_age

  ################
  ### INCLUDES ###
  ################

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  #################
  ### RELATIONS ###
  #################

  belongs_to :tax

  ###################
  ### VALIDATIONS ###
  ###################


  validates :year,
            numericality: {only_integer: true},
            presence: true

  validates :men_from,
            numericality: {only_integer: true, greater_than: 0}

  validates :men_to,
            numericality: {only_integer: true, greater_than: 0}

  validates :women_from,
            numericality: {only_integer: true, greater_than: 0}

  validates :women_to,
            numericality: {only_integer: true, greater_than: 0}

  validates :employer_percent,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :employee_percent,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  ########################
  ### CLASS METHODS ###
  ########################

  def self.compute(reference_value, year, infos, tax)
    gender = infos.male? ? 'men' : 'women' # thoses are database prefixes

    data = where(tax_id: tax.id, year: year)
          .where("#{gender}_from <= ? and ? <= #{gender}_to" , *([infos.age] * 2))
          .first

    reference_value = 0.to_money if data.nil?

    if data
      {
        taxed_value: reference_value,
        employee:
        {
          percent: data.employer_percent,
          value: reference_value * (data.employer_percent / 100),
          use_percent: true
        },
        employer:
        {
          percent: data.employee_percent,
          value: reference_value * (data.employee_percent / 100),
          use_percent: true
        }
      }
    else
      {
        taxed_value: 0.to_money,
        employee: {percent: 0, value: 0.to_money, use_percent: true },
        employer: {percent: 0, value: 0.to_money, use_percent: true }
      }
    end
  end

  def self.process_data(tax, data)
    transaction do
      begin
        # parse file and build an array of age tax
        items = CSV.parse(data, encoding: 'UTF-8')[1..-1].map do |row|
          return false if row.size != 7

          # validates integers
          [0,1,2,3,4].each do |i|
            # This will raise an error if the string doesn't represent an integer
            Integer(row[i]) unless row[i].nil?
          end

          # validates floats
          [5,6].each do |i|
            # This will raise an error if the string doesn't represent a float
            Float(row[i]) unless row[i].nil?
          end

          new tax: tax,
              year: row[0],
              men_from: row[1],
              men_to: row[2],
              women_from: row[3],
              women_to: row[4],
              employer_percent: row[5],
              employee_percent: row[6]
        end
        return if items.empty?

        # remove currently stored data for the same year(s)
        items.map(&:year).uniq.each do |year|
          where(year: year, tax_id: tax.id).destroy_all
        end

        # try to save taxes (it's a transaction...)
        items.each(&:save!)
        true # returns true instead of the tax
      rescue
        false
      end
    end
  end

end
