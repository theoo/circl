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

class AffairsProductsCategory < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################


  #################
  ### CALLBACKS ###
  #################

  before_validation :set_position_if_none_given, if: Proc.new {|i| i.position.blank? }


  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  has_many    :product_items,
              -> { order(:position) },
              class_name: 'AffairsProductsProgram',
              foreign_key: 'category_id'

  ###################
  ### VALIDATIONS ###
  ###################

  validates :affair_id, presence: true
  validates :position, presence: true
  validates :title, presence: true


  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)
    h[:value]          = product_items.map{|p| p.bid_price.to_money(affair.value_currency)}.sum.to_f
    h[:value_currency] = affair.value.currency.try(:iso_code)
    h
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  private

  def set_position_if_none_given
    if affair
      last_item = affair.product_categories.order(:position).last
      if last_item
        self.position = last_item.position + 1
      end
    end
    self.position ||= 1
  end

end
