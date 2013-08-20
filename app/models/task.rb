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
  before_save   :compute_value

  #################
  ### RELATIONS ###
  #################

  belongs_to  :affair

  # made for this person
  has_one     :owner, :through => :affair

  # made by this person
  belongs_to  :executer, :class_name => Person

  belongs_to  :task_type

  belongs_to  :salary, :class_name => 'Salaries::Salary'

  # Money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_with DateValidator, :attribute => :date
  validates_presence_of :description,
                        :affair_id,
                        :date,
                        :duration,
                        :task_type_id,
                        :value_in_cents,
                        :value_currency

  validate :date_not_in_the_future
  validate :duration_is_positive

  # Validate fields of type 'text' length
  validates_length_of :description, :maximum => 65536


  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)

    h[:person_name] = person.try(:name)
    h[:errors] = errors

    h
  end

  private

  def date_not_in_the_future
    if date && date > Date.today
      errors.add(:date, I18n.t('common.errors.date_cannot_be_in_the_future'))
      return false
    end
  end

  def duration_is_positive
    if duration && duration < 0
      errors.add(:duration, I18n.t('common.errors.duration_must_be_positive'))
      return false
    end
  end

  def update_elasticsearch
    person.update_index unless tracked_changes.empty?
  end

  def compute_value
    # TODO: fetch initial value of an hour
    hour = 100
    self.value = duration * value * self.task_type.ratio
  end

end
