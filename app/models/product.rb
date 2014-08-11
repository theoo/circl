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

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing

  #################
  ### CALLBACKS ###
  #################

  before_validation do
    self.price_to_unit_rate ||= 1
    self.unit_symbol ||= "pc" # units are defined in translations
  end

  #################
  ### RELATIONS ###
  #################

  belongs_to :provider, class_name: 'Person'
  belongs_to :after_sale, class_name: 'Person'

  has_many :variants, class_name: 'ProductVariant',
                      dependent: :destroy

  has_many :product_items, class_name: 'AffairsProductsProgram',
                           dependent: :destroy

  has_many :programs, through: :product_items
  has_many :affairs,  through: :product_items

  scope :actives,  -> { where(archive: false)}
  scope :archived, -> { where(archive: true)}


  ###################
  ### VALIDATIONS ###
  ###################

  validates :key, presence: true,
                  length: { maximum: 255 },
                  uniqueness: true
  validates :unit_symbol, presence: true,
                          length: {maximum: 255}
  validates :price_to_unit_rate, presence: true


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
      { id: v.id,
        product_id: v.product_id,
        program_group: v.program_group,
        title: v.title,
        buying_price: v.buying_price.to_f,
        buying_price_currency: v.buying_price_currency,
        selling_price: v.selling_price.to_f,
        selling_price_currency: v.selling_price_currency,
        art: v.art.to_f,
        art_currency: v.art_currency,
        created_at: v.created_at,
        updated_at: v.updated_at }
    end

    h[:errors]         = errors

    h
  end

  def available_programs
    # TODO opposit joins
    # Product.find(3).variants.joins("LEFT JOIN product_programs
    # ON product_variants.program_group = product_programs.program_group")
    program_groups = self.variants.map(&:program_group)
    ProductProgram.where(program_group: program_groups)
  end

  def unit_symbol_translated
    I18n.t!("product.units.#{self.unit_symbol}.symbol")
  rescue
    self.unit_symbol
  end


  ########################
  ### INSTANCE METHODS ###
  ########################

  private

end
