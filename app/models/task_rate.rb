# == Schema Information
#
# Table name: task_rates
#
#  id             :integer          not null, primary key
#  title          :string(255)      not null
#  description    :text
#  value_in_cents :integer          not null
#  value_currency :string(255)      default("CHF")
#  archive        :boolean          default(FALSE)
#  created_at     :datetime
#  updated_at     :datetime
#

class TaskRate < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_destroy :prevent_if_client_present

  #################
  ### RELATIONS ###
  #################

  has_many :people, dependent: :nullify

  # Money
  money :value

  scope :actives,  -> { where(archive: false)}
  scope :archived, -> { where(archive: true)}

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates :value, presence: true,
                    numericality: {greater_than: 0,
                                      less_than_or_equal: 99999999.99 } # BVR limit

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536

  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)
    h[:value]        = value.to_f
    h[:people_count] = people.count
    h[:errors]       = errors
    h
  end

  private

  def prevent_if_client_present
    if people.count > 0
      errors.add(:base, I18n.t('task_rate.errors.cannot_destroy_if_client_present'))
      return false
    end
  end

end
