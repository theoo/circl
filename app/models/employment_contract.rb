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
# Table name: employment_contracts
#
# *id*::                 <tt>integer, not null, primary key</tt>
# *person_id*::          <tt>integer</tt>
# *percentage*::         <tt>integer</tt>
# *interval_starts_on*:: <tt>date</tt>
# *interval_ends_on*::   <tt>date</tt>
# *description*::        <tt>text, default("")</tt>
# *created_at*::         <tt>datetime</tt>
# *updated_at*::         <tt>datetime</tt>
#--
# == Schema Information End
#++

class EmploymentContract < ActiveRecord::Base
  
  ################
  ### INCLUDES ###
  ################

  include ChangesTracker

  #################
  ### CALLBACKS ###
  #################

  before_destroy :check_interval_is_in_past_or_future
  after_commit :update_elasticsearch

  #################
  ### RELATIONS ###
  #################

  belongs_to :person


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :percentage, :interval_starts_on, :interval_ends_on, :person_id

  validates_numericality_of :percentage,
                            :greater_than_or_equal_to => 0,
                            :less_than_or_equal_to => 100,
                            :only_integer => true

  validates_with IntervalValidator
  validates_with DateValidator, :attribute => :interval_starts_on
  validates_with DateValidator, :attribute => :interval_ends_on

  validate :person_exists

  # Validate fields of type 'text' length
  validates_length_of :description, :maximum => 65536


  ########################
  ### INSTANCE METHODS ###
  ########################

  # returns true if today is included in interval
  def is_running?
    today = Date.today
    today >= interval_starts_on && today <= interval_ends_on
  end

  protected

  # validation method
  def person_exists
    if person_id # person_id should exist, check validates_pesence_of
      unless Person.exists?(person_id)
        errors.add(:person_id,
                   I18n.t('employment_contract.errors.person_does_not_exist'))
      end
    end
  end

  # callback
  # if today is in range of interval abort
  def check_interval_is_in_past_or_future
    today = Date.today
    unless today > interval_ends_on || today < interval_starts_on
      errors.add(:base,
                 I18n.t('employment_contract.errors.cant_delete_contract_if_current'))
      false
    end
  end

  ## attributes overridden - JSON API
  #def as_json(options = nil)
  #  h = super(options)
  #
  #  h[:person_name] = person.try(:name)
  #
  #  # add errors if any
  #  h[:errors] = errors
  #  h
  #end


  private

  def update_elasticsearch
    person.update_index unless tracked_changes.empty?
  end

end
