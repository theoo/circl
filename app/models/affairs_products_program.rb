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

  before_validation do
    unless category
      if affair
        if affair.product_categories.count > 0
          self.category = affair.product_categories.first
        else
          self.category = affair.product_categories
            .create(title: ApplicationSetting.value("default_product_category_name"))
        end
      end
    end
  end

  before_validation :set_position_if_none_given, if: Proc.new {|i| i.position.blank? }

  # TODO attr_accessor for value reset, allow value of 0
  before_save :update_value, if: 'value_in_cents.blank? || value_in_cents == 0'

  after_save 'affair.update_on_prestation_alteration'
  after_save :remove_empty_categories
  after_destroy :remove_empty_categories

  #################
  ### RELATIONS ###
  #################

  acts_as_tree

  belongs_to :affair
  belongs_to :product
  belongs_to :program, class_name: "ProductProgram"
  belongs_to :category, class_name: "AffairsProductsCategory"

  attr_accessor :template

  ###################
  ### VALIDATIONS ###
  ###################

  validates :affair_id, presence: true
  validates :product_id, presence: true
  validates :program_id, presence: true
  validates :category_id, presence: true
  validates :position, presence: true
  validates :value_currency, presence: true
  validates :value, presence: true
  validates :position, presence: true
  # NOTE unable to validate uniqueness when reordering items
  #, uniqueness: { scope: :affair_id }
  validates :quantity, presence: true
  # TODO edit if this validation should exists in application settings.
  # validate :uniquness_of_jointure, if: Proc.new {|i| i.new_record?}
  validate :tree_depth, if: 'parent'
  validates_numericality_of :bid_percentage,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100,
    only_integer: false,
    unless: "bid_percentage.blank?"

  money :value

  ########################
  #### CLASS METHODS #####
  ########################

  # If no from/to argument are given it will update position of the entire list
  # FIXME not sure the behavior is correct withou from/to

  def self.fix_children
    @pis.each do |pi|
      if pi.parent
        if pi.position.floor != pi.parent.position.floor
          change_position(pi, @pis.index(pi), @pis.index(pi.parent) + 1)
        end
      end
    end
  end

  def self.update_position(id, from = nil, to = nil)
    item = find(id)

    true
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  def update_table_index_position(to_pos)
    # get siblings as one dimention table
    positions = affair.product_items.to_a

    # find current objet index in table
    from_pos = positions.index(self)

    # move the object in the table
    p = positions.delete_at from_pos
    positions.insert(to_pos, p)

    # rename position of all items
    AffairsProductsProgram.transaction do

      mapping = affair.product_items_positions(positions).keys

      positions.each_with_index do |e,i|
        new_pos = mapping[i]
        e.update_attributes(position: new_pos) if e.position != new_pos
      end
    end

    true
  end

  def get_positions_as_table_index(pos)
    # return table index
    positions = affair.product_items_positions
    item = positions[pos]
    positions.values.index(item)
  end

  def get_table_index_as_position(index)
    # return position as float with two decimal precision
    affair.product_items_positions.keys[index]
  end

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:program_key]             = program.try(:key)
    h[:program_title]           = program.try(:title)
    h[:program_desc]            = program.try(:description)
    h[:parent_key]              = parent.try(:product).try(:key)
    h[:parent_title]            = parent.try(:product).try(:title)
    h[:parent_desc]             = parent.try(:product).try(:description).try(:exerpt)
    h[:has_accessories]         = product.try(:has_accessories)
    h[:key]                     = product.try(:key)
    h[:title]                   = variant.title.blank? ? product.title : [product.title, variant.title].join(" / ")
    h[:description]             = product.try(:description)
    h[:unit_price]              = unit_price.try(:to_f)
    h[:unit_price_currency]     = unit_price.currency.try(:iso_code)
    h[:value]                   = value.to_f
    h[:value_currency]          = value.currency.try(:iso_code)
    h[:bid_price]               = bid_price.to_f
    h[:bid_price_currency]      = bid_price.currency.try(:iso_code)
    h[:computed_value]          = compute_value.to_f
    h[:computed_value_currency] = compute_value.currency.try(:iso_code)
    h[:art]                     = variant ? variant.art.to_f : nil
    h[:art_currency]            = variant ? variant.art.currency.try(:iso_code) : nil
    h[:unit_symbol]             = product.try(:unit_symbol)
    h[:category]                = category.try(:title)
    h[:provider_name]           = product.try(:provider).try(:name)
    h[:created_at]              = created_at.try(:to_date) # Override datetime
    h[:ordered_at]              = ordered_at.try(:to_date) # Override datetime
    h[:confirmed_at]            = confirmed_at.try(:to_date) # Override datetime
    h[:delivery_at]             = delivery_at.try(:to_date) # Override datetime
    h[:warranty_begin]          = warranty_begin.try(:to_date) # Override datetime
    h[:warranty_end]            = warranty_end.try(:to_date) # Override datetime

    h[:errors]         = errors

    h
  end

  # In some rare case, a given item may not have a corresponding program_group, which then returns a nil object.
  def variant
    if program
      product.variants.where(program_group: program.program_group).first
    end
  end

  # The value of an item depends on its variant and its program
  # An item may not have value (free accessories)
  def compute_value
    (unit_price * quantity).to_money(value_currency)
  end

  def unit_price
    if variant
      variant.selling_price / product.price_to_unit_rate
    else
      0.to_money
    end
  end

  def bid_price
    if bid_percentage
      (value.to_f - (value.to_f / 100.0 * bid_percentage)).to_money(value_currency)
    else
      value
    end
  end

  #
  # Discount value, helper for templates
  #
  # @return [Money] value of discount
  def discount_value
    value - bid_price
  end

  #
  # Does this item have a discount?
  #
  # @return [Boolean] true if the bid_price and the value are not equal
  def discount?
    value != bid_price
  end

  # override sibilings method so nil parent doesn't returns the whole product_items database
  def siblings
    if parent
      super
    else
      s = affair.product_items.where(parent: nil)
      s = s.where("id != ?", id) if id
      s
    end
  end

  def siblings_and_self
    if parent
      affair.product_items.where(parent: parent.id)
    else
      affair.product_items.where(parent: nil) if affair
    end
  end

  private

  def update_value
    original_currency = self.value_currency
    self.value = compute_value.to_money(original_currency)
  end

  def uniquness_of_jointure
    if self.class.where(affair_id: affair_id, product_id: product_id, program_id: program_id).count > 0
      errors.add :base, I18n.t("product_variant.errors.this_relation_already_exists")
      false
    end
  end

  def set_position_if_none_given
    last_item = siblings.last if siblings

    if last_item
      self.position = last_item.position + 1
    else
      self.position = 1
    end
  end

  def remove_empty_categories
    # TODO improve SQL
    ids = affair.product_items.map(&:category_id).uniq
    empty_categories = affair.product_categories.where("id NOT IN (?)", ids)
    empty_categories.each{|c| c.destroy} unless empty_categories.empty?
  end

  def tree_depth
    if parent.parent
      errors.add :base, I18n.t("product_variant.errors.parent_cannot_be_the_child_of_another_product_item")
      false
    end
  end

end
