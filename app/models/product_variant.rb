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

class ProductVariant < ActiveRecord::Base

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


  #################
  ### RELATIONS ###
  #################

  belongs_to :product
  belongs_to :program,      :class_name => 'ProductProgram'

  has_many :product_items,  :class_name => 'AffairsProductVariant',
                            :foreign_key => 'variant_id'

  has_many :affairs,        :through => :product_items

  money :price
  money :list_price
  money :art

  ###################
  ### VALIDATIONS ###
  ###################

  validates :key, :presence => true, 
                  :length => { :maximum => 255 }
  validates_uniqueness_of :key, :scope => :product_id
  validates :price, :presence => true
  validates :price_in_cents, :presence => true

  ########################
  #### CLASS METHODS #####
  ########################


  ########################
  ### INSTANCE METHODS ###
  ########################

end
