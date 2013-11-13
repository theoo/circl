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

class Product < ActiveRecord::Base

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

  belongs_to :provider, :class_name => 'Person'
  belongs_to :after_sale, :class_name => 'Person'

  has_many  :variants,  :class_name => 'ProductVariant',
                        :dependent => :destroy

  scope :actives, Proc.new { where(:archive => false)}
  scope :archived, Proc.new { where(:archive => true)}

  ###################
  ### VALIDATIONS ###
  ###################

  validates :key, :presence => true,
                  :length => { :maximum => 255 },
                  :uniqueness => true

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:provider_name]   = provider.try(:name)
    h[:after_sale_name] = after_sale.try(:name)

    h[:variants_count] = variants.count

    h[:variants] = variants.map do |v|
      { :id            => v.id,
        :product_id    => v.product_id,
        :program_group => v.program_group,
        :title         => v.title,
        :description   => v.description,
        :buying_price  => v.buying_price.to_f,
        :selling_price => v.selling_price.to_f,
        :art           => v.art.to_f,
        :created_at    => v.created_at,
        :updated_at    => v.updated_at }
    end

    h[:errors]         = errors

    h
  end


  ########################
  ### INSTANCE METHODS ###
  ########################

  private

end
