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

class Extra < ActiveRecord::Base

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

  before_validation :set_position_if_none_given, if: Proc.new {|i| i.position.blank? }

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  has_one     :owner, through: 'affair'

  money :value
  money :vat

  ###################
  ### VALIDATIONS ###
  ###################

  validates :title, presence: true
  validates :value, presence: true,
                    numericality: { less_than_or_equal: 99999999.99, greater_than: 0 }
  validates :position, presence: true
  # Unable to validae uniqueness when reordering
  # , uniqueness: { scope: :affair_id }
  validates :quantity, presence: true

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum:  65535
  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:total_value]          = total_value.to_f
    h[:total_value_currency] = total_value.currency.iso_code
    h[:value]                = value.to_f
    h[:vat]                  = vat.to_f
    h[:errors]               = errors

    h
  end

  def total_value
    value * quantity
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  private

  def set_position_if_none_given
    last_item = self.affair.extras.order(:position).last
    if last_item
      self.position = last_item.position + 1
    else
      self.position = 1
    end
  end

end
