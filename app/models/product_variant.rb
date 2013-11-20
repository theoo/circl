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

  money :buying_price
  money :selling_price
  money :art

  ###################
  ### VALIDATIONS ###
  ###################

  validates :program_group, :presence => true,
                            :length => { :maximum => 255 }
  validates_uniqueness_of :program_group, :scope => :product_id
  validates :selling_price, :presence => true, :numericality => {:greater_than => 0}
  validates :selling_price_in_cents, :presence => true, :numericality => {:greater_than => 0}

  ########################
  #### CLASS METHODS #####
  ########################


  ########################
  ### INSTANCE METHODS ###
  ########################

end
