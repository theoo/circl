# == Schema Information
#
# Table name: salaries_items
#
#  id             :integer          not null, primary key
#  parent_id      :integer
#  salary_id      :integer          not null
#  position       :integer          not null
#  title          :string(255)      not null
#  value_in_cents :integer          not null
#  category       :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  value_currency :string(255)      default("CHF"), not null
#

class Salaries::Item < ApplicationRecord

  #################
  ### CALLBACKS ###
  #################

  after_create do
    if salary.is_reference
      salary.synchronize_tax_data
    end
  end

  after_update do
    salary.synchronize_tax_data
  end

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### RELATIONS ###
  #################

  belongs_to :salary,
             class_name: 'Salaries::Salary'

  # monitored_habtm :taxes,
  has_and_belongs_to_many :taxes,
                  class_name: 'Salaries::Tax',
                  join_table: 'salaries_items_taxes'

  # Template
  belongs_to :reference,
             class_name: 'Salaries::Item',
             foreign_key: :parent_id

  # money
  money :value

  ###############
  #### SCOPE ####
  ###############

  default_scope { order('position ASC') }
  scope :with_category, -> { where('length(category) > 0') }

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates_presence_of :value
  # TODO Validate presence of tax data

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255
  validates_length_of :category, maximum: 255

  ########################
  ### INSTANCE METHODS ###
  ########################

  def is_reference?
    salary.is_reference?
  end

  def empty?
    # FIXME add more
    title.blank? && category.blank?
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:tax_ids] = tax_ids
    h[:value] = value.to_f

    h[:errors] = errors
    h
  end

  def has_reference?
    reference.nil? == false
  end

  # tree methods, for references
  def children
    Salaries::Item.where(parent_id: id)
  end

  # tree methods, for items
  def siblings
    Salaries::Item.where(parent_id: parent_id)
                  .where("id != ?", id)
  end

end
