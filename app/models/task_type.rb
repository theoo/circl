# == Schema Information
#
# Table name: task_types
#
#  id             :integer          not null, primary key
#  title          :string(255)      default(""), not null
#  description    :text             default("")
#  ratio          :float            not null
#  value_in_cents :integer
#  value_currency :string(255)      default("CHF")
#  archive        :boolean          default(FALSE)
#

class TaskType < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_validation :set_defaults
  before_destroy :prevent_if_task_present

  #################
  ### RELATIONS ###
  #################

  has_many :tasks, dependent: :nullify

  scope :actives,  -> { where(archive: false)}
  scope :archived, -> { where(archive: true)}

  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validate :should_have_a_ratio_or_a_value

  def as_json(options = nil)
    h = super(options)
    h[:value]       = value.to_f
    h[:tasks_count] = tasks.count
    h[:errors]      = errors
    h
  end

  private

  def should_have_a_ratio_or_a_value
    if ratio.blank? and value_in_cents == 0
      errors.add(:base, I18n.t('task_type.errors.should_have_a_ratio_or_a_title'))
      return false
    end
  end

  def prevent_if_task_present
    if tasks.count > 0
      errors.add(:base, I18n.t('task_type.errors.cannot_destroy_if_task_present'))
      return false
    end
  end

  def set_defaults
    self.ratio ||= 0
  end

end
