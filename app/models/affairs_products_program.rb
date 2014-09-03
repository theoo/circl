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

class AffairsProductsProgram < ActiveRecord::Base

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

  before_save do
    self.category ||= product.category
  end

  before_save :update_value, if: 'value_in_cents.blank?'

  #################
  ### RELATIONS ###
  #################

  acts_as_tree

  belongs_to :affair
  belongs_to :product
  belongs_to :program, class_name: "ProductProgram"

  ###################
  ### VALIDATIONS ###
  ###################

  validates :affair_id, presence: true
  validates :product_id, presence: true
  validates :program_id, presence: true
  validates :position, presence: true
  # NOTE unable to validate uniqueness when reordering items
  #, uniqueness: { scope: :affair_id }
  validates :quantity, presence: true
  # TODO edit if this validation should exists in application settings.
  # validate :uniquness_of_jointure, if: Proc.new {|i| i.new_record?}
  validates_numericality_of :bid_percentage,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100,
                            only_integer: false,
                            unless: "bid_percentage.blank?"

  money :value

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:program_key]        = program.try(:key)
    h[:parent_key]         = parent.try(:product).try(:key)
    h[:has_accessories]    = product.try(:has_accessories)
    h[:key]                = product.try(:key)
    h[:title]              = variant.title.blank? ? product.title : [product.title, variant.title].join(" / ")
    h[:description]        = product.try(:description)
    h[:value]              = value.to_f
    h[:value_currency]     = value.currency.try(:iso_code)
    h[:bid_price]          = bid_price.to_f
    h[:bid_price_currency] = bid_price.currency.try(:iso_code)
    h[:unit_symbol]        = product.try(:unit_symbol)

    h[:errors]         = errors

    h
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  # In some rare case, a given item may not have a corresponding program_group, which then returns a nil object.
  def variant
    if program
      product.variants.where(program_group: program.program_group).first
    end
  end

  # The value of an item depends on its variant and its program
  # An item may not have value (free accessories)
  def compute_value
    if variant
      variant.selling_price * quantity / product.price_to_unit_rate
    else
      0.to_money
    end
  end

  def bid_price
    if bid_percentage
      value - (value / 100 * bid_percentage)
    else
      value
    end
  end

  private

  def update_value
    self.value = compute_value
  end

  def set_position_if_none_given
    last_item = self.affair.product_items.order(:position).last
    if last_item
      if parent
        insert_in_list_if_accessory
      else
        self.position = last_item.position + 1
      end
    else
      self.position = 1
    end
  end

  def uniquness_of_jointure
    if self.class.where(affair_id: affair_id, product_id: product_id, program_id: program_id).count > 0
      errors.add :base, I18n.t("product_variant.errors.this_relation_already_exists")
      false
    end
  end

  def insert_in_list_if_accessory
    siblings = affair.product_items.all

    last_child = parent.children.order(:position).map(&:id)
    last_child.delete(self.id) unless new_record?
    if last_child.size > 0
      i = siblings.to_a.index(affair.product_items.find(last_child.last)) + 1
    else
      i = siblings.to_a.index(parent) + 1
    end

    self.position = i
    siblings.insert i, self

    siblings.each_with_index do |s, i|
      s.update_attributes(position: i) unless s == self
    end
  end

end
