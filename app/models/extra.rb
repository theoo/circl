# == Schema Information
#
# Table name: extras
#
#  id             :integer          not null, primary key
#  affair_id      :integer
#  title          :string(255)
#  description    :text
#  value_in_cents :integer
#  value_currency :string(255)
#  quantity       :float
#  position       :integer
#  created_at     :datetime
#  updated_at     :datetime
#  vat_in_cents   :integer          default(0), not null
#  vat_currency   :string(255)      default("CHF"), not null
#  vat_percentage :float
#

class Extra < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_save :set_vat_percentage, id: 'vat_percentage.blank?'
  before_validation :set_position_if_none_given, if: Proc.new {|i| i.position.blank? }
  after_save do
    affair.update_on_prestation_alteration
  end

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  has_one     :owner, through: 'affair'

  money :value
  money :vat

  ###################
  ### VALIDATIONS ###
  ###################

  validates :title, presence: true
  validates :value, presence: true
                    # numericality: { less_than_or_equal: 99999999.99, greater_than: 0 }
  validates :position, presence: true
  # Unable to validae uniqueness when reordering
  # , uniqueness: { scope: :affair_id }
  validates :quantity, presence: true

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum:  65535

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:total_value]          = total_value.to_f
    h[:total_value_currency] = total_value.currency.iso_code
    h[:value]                = value.to_f
    h[:vat]                  = vat.to_f
    h[:errors]               = errors

    h
  end

  def total_value
    value * quantity
  end

  def compute_vat
    value / 100.0 * vat_percentage
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  private

  def set_position_if_none_given
    last_item = self.affair.extras.order(:position).last
    if last_item
      self.position = last_item.position + 1
    else
      self.position = 1
    end
  end

  def set_vat_percentage
    self.vat_percentage = affair.vat_percentage
    self.vat_percentage ||= ApplicationSetting.value("service_vat_rate")
  end

end
