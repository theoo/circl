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

class Currency < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_save :default_values

  #################
  ### RELATIONS ###
  #################

  has_many :rates_as_base, # buy
    :class_name => 'CurrencyRate',
    :foreign_key => 'from_currency_id'

  has_many :rates_as_exchange, # sell
    :class_name => 'CurrencyRate',
    :foreign_key => 'to_currency_id'

  ###################
  ### VALIDATIONS ###
  ###################

  validates :iso_code, :presence => true, :length => {:is => 3}
  validates :iso_numeric, :length => {:maximum => 255}
  validates :name, :length => {:maximum => 255}
  validates :symbol, :length => {:maximum => 3}
  validates :subunit, :length => {:maximum => 255}
  validates :separator, :length => {:maximum => 255}
  validates :delimiter, :length => {:maximum => 255}

  validates :priority, :numericality => true, :unless => Proc.new {|c| c.priority.blank? }
  validates :subunit_to_unit, :numericality => true, :unless => Proc.new {|c| c.subunit_to_unit.blank? }

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

end
