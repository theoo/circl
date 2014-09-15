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
      if affair.product_categories.count > 0
        self.category = affair.product_categories.first
      else
        self.category = affair.product_categories
          .create(title: ApplicationSetting.value("default_product_category_name"))
      end
    end
  end

  before_validation :set_position_if_none_given, if: Proc.new {|i| i.position.blank? }

  before_save :update_value, if: 'value_in_cents.blank? || value_in_cents == 0'

  after_save :remove_empty_categories

  #################
  ### RELATIONS ###
  #################

  acts_as_tree

  belongs_to :affair
  belongs_to :product
  belongs_to :program, class_name: "ProductProgram"
  belongs_to :category, class_name: "AffairsProductsCategory"

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
  def self.update_position(id, from = nil, to = nil)
    item = find(id)

    AffairsProductsProgram.transaction do
      # Scope is the affair and not the category
      # siblings = item.category.product_items.all.to_a

      siblings = item.affair.product_items.all.to_a

      if from and to
        p = siblings.delete_at from - 1
        siblings.insert(to - 1, p)
        siblings.delete(nil) # If there is holes in list they will be replace by nil
      end

      siblings.each_with_index do |s, i|
        u = AffairsProductsProgram.find(s.id)
        u.update_attributes(position: i + 1)
      end
    end
    true
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    # NOTE currently products currency is forced to affair currency
    affair_currency = affair.try(:value).try(:currency).try(:iso_code)

    h[:program_key]             = program.try(:key)
    h[:parent_key]              = parent.try(:product).try(:key)
    h[:has_accessories]         = product.try(:has_accessories)
    h[:key]                     = product.try(:key)
    h[:title]                   = variant.title.blank? ? product.title : [product.title, variant.title].join(" / ")
    h[:description]             = product.try(:description)
    h[:unit_price]              = unit_price.to_money(affair_currency).try(:to_f)
    h[:unit_price_currency]     = affair_currency
    h[:value]                   = value.to_money(affair_currency).to_f
    h[:value_currency]          = affair_currency
    h[:bid_price]               = bid_price.to_money(affair_currency).to_f
    h[:bid_price_currency]      = affair_currency
    h[:computed_value]          = compute_value.to_money(affair_currency).to_f
    h[:computed_value_currency] = affair_currency
    h[:art]                     = variant ? variant.art.to_money(affair_currency).to_f : nil
    h[:art_currency]            = affair_currency
    h[:unit_symbol]             = product.try(:unit_symbol)
    h[:category]                = category.try(:title)

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
    unit_price * quantity
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

  private

  def update_value
    self.value = compute_value
  end

  def set_position_if_none_given
    # TODO set position within category
    # Scope it from the affair and not the category
    # last_item = category.product_items.order(:position).last

    last_item = affair.product_items.order(:position).last

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

  def remove_empty_categories
    # TODO improve SQL
    ids = affair.product_items.map(&:category_id).uniq
    empty_categories = affair.product_categories.where("id NOT IN (?)", ids)
    empty_categories.each{|c| c.destroy} unless empty_categories.empty?
  end

end
