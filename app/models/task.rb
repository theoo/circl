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

# == Schema Information
#
# Table name: tasks
#
# *id*::             <tt>integer, not null, primary key</tt>
# *executer_id*::    <tt>integer, not null</tt>
# *date*::           <tt>date</tt>
# *description*::    <tt>text, default("")</tt>
# *duration*::       <tt>integer</tt>
# *created_at*::     <tt>datetime</tt>
# *updated_at*::     <tt>datetime</tt>
# *affair_id*::      <tt>integer, not null</tt>
# *task_type_id*::   <tt>integer, not null</tt>
# *value_in_cents*:: <tt>integer, default(0), not null</tt>
# *value_currency*:: <tt>string(255), default("CHF"), not null</tt>
# *salary_id*::      <tt>integer</tt>
#--
# == Schema Information End
#++

class Task < ActiveRecord::Base

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

  after_commit  :update_elasticsearch
  before_save   :set_value
  after_save 'affair.update_on_prestation_alteration'

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  # made for this person
  has_one     :owner, through: :affair
  # made by this person
  belongs_to  :executer, class_name: 'Person'
  belongs_to  :task_type
  belongs_to  :salary, class_name: 'Salaries::Salary'

  scope :availables, -> { where(archive: false)}

  # Money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_with DateValidator, attribute: :start_date
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
    h[:owner_name]              = owner.try(:name)
    h[:executer_id]             = executer.try(:id)
    h[:executer_name]           = executer.try(:name)
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

  def update_elasticsearch
    person.update_index unless self.changes.empty?
  end

end
