# == Schema Information
#
# Table name: product_variants
#
#  id                     :integer          not null, primary key
#  product_id             :integer          not null
#  program_group          :string(255)      not null
#  title                  :string(255)
#  buying_price_in_cents  :integer
#  buying_price_currency  :string(255)      default("CHF"), not null
#  selling_price_in_cents :integer          not null
#  selling_price_currency :string(255)      default("CHF")
#  art_in_cents           :integer
#  art_currency           :string(255)      default("CHF")
#  created_at             :datetime
#  updated_at             :datetime
#  vat_in_cents           :integer          default(0), not null
#  vat_currency           :string(255)      default("CHF"), not null
#  vat_percentage         :integer
#

class ProductVariant < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_validation do
    # TODO migrate column type to default 0 and remove validation
    self.selling_price_in_cents ||= 0
  end


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

  validates :program_group, presence: true,
    length: { maximum: 255 },
    inclusion: { in: ProductProgram.select("DISTINCT product_programs.program_group").map(&:program_group) }

  validates_uniqueness_of :program_group, scope: :product_id
  validates :selling_price, presence: true
  validates :selling_price_in_cents, presence: true

  ########################
  #### CLASS METHODS #####
  ########################


  ########################
  ### INSTANCE METHODS ###
  ########################

end
