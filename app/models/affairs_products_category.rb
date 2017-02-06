# == Schema Information
#
# Table name: affairs_products_categories
#
#  id        :integer          not null, primary key
#  affair_id :integer          not null
#  title     :string(255)
#  position  :integer          not null
#


class AffairsProductsCategory < ApplicationRecord

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
              class_name: 'ProductItem',
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
