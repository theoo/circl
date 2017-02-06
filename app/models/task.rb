class Task < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # TODO: Move this to jsbuilder
  class TaskHelper
    include ActionView::Helpers::DateHelper
  end

  def helper
    @h || TaskHelper.new
  end

  # include ChangesTracker
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  after_commit  :update_people_in_search_engine
  before_save   :set_value

  after_save do
    self.affair.update_on_prestation_alteration
  end

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  # made for this person
  has_one     :owner, through: :affair

  # whom actually made the service
  belongs_to  :executer, class_name: 'Person'
  # whom created the task
  belongs_to  :creator, class_name: 'Person'

  belongs_to  :task_type
  belongs_to  :salary, class_name: 'Salaries::Salary'

  scope :availables, -> { where(archive: false)}

  # Money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_with Validators::Date, attribute: :start_date
  validates_presence_of :description,
                        :affair_id,
                        :task_type_id,
                        :executer_id,
                        :start_date,
                        :value_in_cents,
                        :value_currency

  validate :duration_is_required_if_selected_task_type_have_a_ratio, if: 'task_type_id'
  validate :duration_is_positive
  validate :owner_should_have_a_task_rate, if: 'affair_id'

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536

  attr_accessor :template

  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)
    h[:task_type_title]         = task_type.try(:title)
    h[:affair_title]            = affair.try(:title)
    h[:owner_id]                = owner.try(:id)
    h[:owner_name]              = owner.try(:name)
    h[:executer_id]             = executer.try(:id)
    h[:executer_name]           = executer.try(:name)
    h[:creator_id]              = creator.try(:id)
    h[:creator_name]            = creator.try(:name)
    h[:duration_in_words]       = translated_duration
    h[:value]                   = value.to_f
    h[:value_currency]          = value.currency.try(:iso_code)
    h[:computed_value]          = compute_value.to_f
    h[:computed_value_currency] = compute_value.currency.try(:iso_code)
    h[:errors]                  = errors
    h
  end

  def end_date
    start_date + duration.minutes
  end

  def duration_in_hours
    duration / 60.0
  end

  def translated_duration
    helper.distance_of_time(duration.minutes)
  end

  def compute_value
    if task_type.ratio
      value = owner.task_rate.value * duration_in_hours * task_type.ratio
    else
      value = task_type.value * duration_in_hours
    end

    # task type may be another currency than task
    value.exchange_to(value_currency)
  end

  private

  def set_value
    # reset value only if none given
    if value_in_cents.blank? or value == 0.to_money
      self.value = compute_value
    end
  end

  def owner_should_have_a_task_rate
    if ! owner.task_rate
      errors.add(:base, I18n.t('task.errors.owner_should_have_a_task_rate'))
      return false
    end
  end

  def duration_is_required_if_selected_task_type_have_a_ratio
    if task_type.ratio and duration.blank?
      errors.add(:base, I18n.t('task.errors.duration_is_required_if_selected_task_type_have_a_ratio'))
      return false
    end
  end

  def duration_is_positive
    if duration && duration < 0
      errors.add(:duration, I18n.t('task.errors.duration_must_be_positive'))
      return false
    end
  end

  # FIXME Why this ?
  def update_people_in_search_engine
    person.update_search_engine unless self.changes.empty?
  end

end
