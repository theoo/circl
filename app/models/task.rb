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

  include ChangesTracker
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  after_commit  :update_elasticsearch
  before_save   :set_value

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair
  # made for this person
  has_one     :owner, :through => :affair
  # made by this person
  belongs_to  :executer, :class_name => 'Person'
  belongs_to  :task_type
  belongs_to  :salary, :class_name => 'Salaries::Salary'

  scope :availables, Proc.new { where(:archive => false)}

  # Money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_with DateValidator, :attribute => :start_date
  validates_presence_of :description,
                        :affair_id,
                        :task_type_id,
                        :executer_id,
                        :start_date,
                        :duration,
                        :value_in_cents,
                        :value_currency

  validate :duration_is_positive
  validate :owner_should_have_a_task_rate

  # Validate fields of type 'text' length
  validates_length_of :description, :maximum => 65536

  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)
    h[:owner_name] = owner.try(:name)
    h[:executer_name] = executer.try(:name)
    h[:errors] = errors
    h
  end

  def end_date
    start_date + duration.minutes
  end

  def duration_in_hours
    duration / 60.0
  end

  def compute_value
    if task_type.ratio
      owner.task_rate.value * duration_in_hours * task_type.ratio
    else
      task_type.value * duration_in_hours
    end
  end

  private

  def set_value
    # reset value only if none given
    if value_in_cents.blank? or value == 0.to_money
      self.value = compute_value unless value
    end
  end

  def owner_should_have_a_task_rate
    if affair_id # there is a validation for affair_id
      if ! owner.task_rate
        errors.add(:base, I18n.t('task_type.errors.owner_should_have_a_task_rate'))
        return false
      end
    end
  end

  def duration_is_positive
    if duration && duration < 0
      errors.add(:duration, I18n.t('task_type.errors.duration_must_be_positive'))
      return false
    end
  end

  def update_elasticsearch
    person.update_index unless tracked_changes.empty?
  end

end
