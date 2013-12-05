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
# Table name: task_types
#
# *id*::          <tt>integer, not null, primary key</tt>
# *title*::       <tt>string(255), default(""), not null</tt>
# *description*:: <tt>text, default("")</tt>
# *ratio*::       <tt>float, not null</tt>
#--
# == Schema Information End
#++

class TaskType < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  #################
  ### RELATIONS ###
  #################

  has_many :tasks, :dependent => :nullify

  scope :actives, Proc.new { where(:archive => false)}
  scope :archived, Proc.new { where(:archive => true)}

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

end
