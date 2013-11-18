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

class AffairsProductVariant < ActiveRecord::Base

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

  before_validation :set_position_if_none_given, :if => Proc.new {|i| i.position.blank? }

  #################
  ### RELATIONS ###
  #################

  acts_as_tree

  belongs_to :affair
  belongs_to :variant, :class_name => "ProductVariant"
  belongs_to :program, :class_name => "ProductProgram"

  has_one :product, :through => :variant

  ###################
  ### VALIDATIONS ###
  ###################

  validates :affair_id, :presence => true
  validates :variant_id, :presence => true
  validates :program_id, :presence => true
  validates :position, :presence => true, :uniqueness => true
  validates :quantity, :presence => true
  validate :uniquness_of_jointure, :if => Proc.new {|i| i.new_record?}

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:program_key]     = program.try(:key)
    h[:parent_key]      = parent.try(:product).try(:key)
    h[:has_accessories] = product.try(:has_accessories)
    h[:key]             = product.try(:key)
    h[:title]           = variant.title.blank? ? product.title : [product.title, variant.title].join(" / ")
    h[:description]     = product.try(:description)
    h[:value]           = value.to_f

    h[:errors]         = errors

    h
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  # The value of an item depends on its variant and its program
  def value
    variant.selling_price
  end

  private

  def set_position_if_none_given
    last_item = self.affair.product_items.order(:position).last
    if last_item
      self.position = last_item.position + 1
    else
      self.position = 1
    end
  end

  def uniquness_of_jointure
    if AffairsProductVariant.where(:affair_id => affair_id, :variant_id => variant_id, :program_id => program_id).count > 0
      errors.add :base, I18n.t("product_variant.errors.this_relation_already_exists")
      false
    end
  end

end
