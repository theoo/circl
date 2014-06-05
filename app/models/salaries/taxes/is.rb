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
# Table name: salaries_taxes_is
#
# *id*::                    <tt>integer, not null, primary key</tt>
# *tax_id*::                <tt>integer, not null</tt>
# *year*::                  <tt>integer, not null</tt>
# *yearly_from_in_cents*::  <tt>integer, not null</tt>
# *yearly_to_in_cents*::    <tt>integer, not null</tt>
# *monthly_from_in_cents*:: <tt>integer, not null</tt>
# *monthly_to_in_cents*::   <tt>integer, not null</tt>
# *hourly_from_in_cents*::  <tt>integer, not null</tt>
# *hourly_to_in_cents*::    <tt>integer, not null</tt>
# *percent_alone*::         <tt>decimal(7, 2)</tt>
# *percent_married*::       <tt>decimal(7, 2)</tt>
# *percent_children_1*::    <tt>decimal(7, 2)</tt>
# *percent_children_2*::    <tt>decimal(7, 2)</tt>
# *percent_children_3*::    <tt>decimal(7, 2)</tt>
# *percent_children_4*::    <tt>decimal(7, 2)</tt>
# *percent_children_5*::    <tt>decimal(7, 2)</tt>
# *created_at*::            <tt>datetime</tt>
# *updated_at*::            <tt>datetime</tt>
#--
# == Schema Information End
#++

# TODO refactor this into a polymorphic association
class Salaries::Taxes::Is < ActiveRecord::Base

  set_table_name :salaries_taxes_is

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

  belongs_to :tax

  # money
  money :yearly_from
  money :yearly_to
  money :monthly_from
  money :monthly_to
  money :hourly_from
  money :hourly_to

  ###################
  ### VALIDATIONS ###
  ###################

  validates :year,
            numericality: {only_integer: true},
            presence: true

  validates :yearly_from_in_cents,
            numericality: {only_integer: true}

  validates :yearly_to_in_cents,
            numericality: {only_integer: true}

  validates :monthly_from_in_cents,
            numericality: {only_integer: true}

  validates :monthly_to_in_cents,
            numericality: {only_integer: true}

  validates :hourly_from_in_cents,
            numericality: {only_integer: true}

  validates :hourly_to_in_cents,
            numericality: {only_integer: true}

  validates :percent_alone,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :percent_married,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :percent_children_1,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :percent_children_2,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :percent_children_3,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :percent_children_4,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  validates :percent_children_5,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}


  ########################
  ### CLASS METHODS ###
  ########################

  def self.compute(reference_value, year, infos, tax)
    data =  where(tax_id: tax.id, year: year)
           .where('yearly_from_in_cents <= ? and ? <= yearly_to_in_cents', *([infos.yearly_salary.cents] * 2))
           .first

    raise RuntimeError, 'cannot find data' unless data

    children_count = infos.children_count
    children_count = 5 if children_count > 5

    percent = if children_count > 0
                data.send("percent_children_#{children_count}")
              elsif infos.married?
                data.percent_married
              else
                data.percent_alone
              end

    {
      taxed_value: reference_value,
      employer:
      {
        percent: 0,
        value: 0.to_money,
        use_percent: true
      },
      employee:
      {
        percent: percent,
        value: reference_value * (percent / 100),
        use_percent: true
      }
    }
  end

  def self.process_data(tax, data)
    transaction do
      begin
        # parse file and build an array of generic tax
        items = data.split(/\r?\n/).map do |line|
          return false if line.size != 72

          new tax: tax,
              year: "20#{line[0..1]}".to_i,
              yearly_from: line[2..8].to_i,
              yearly_to: line[9..15].to_i,
              monthly_from: line[16..22].to_i / 100.0,
              monthly_to: line[23..29].to_i,           # yes, different format!
              hourly_from: line[30..36].to_i / 100.0,
              hourly_to: line[37..43].to_i / 100.0,
              percent_alone: line[44..47].to_i / 100.0,
              percent_married: line[48..51].to_i / 100.0,
              percent_children_1: line[52..55].to_i / 100.0,
              percent_children_2: line[56..59].to_i / 100.0,
              percent_children_3: line[60..63].to_i / 100.0,
              percent_children_4: line[64..67].to_i / 100.0,
              percent_children_5: line[68..71].to_i / 100.0
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
