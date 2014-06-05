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
# Table name: logs
#
# *id*::            <tt>integer, not null, primary key</tt>
# *person_id*::     <tt>integer</tt>
# *resource_id*::   <tt>integer</tt>
# *resource_type*:: <tt>string(255)</tt>
# *action*::        <tt>string(255)</tt>
# *data*::          <tt>text</tt>
# *created_at*::    <tt>datetime</tt>
# *updated_at*::    <tt>datetime</tt>
#--
# == Schema Information End
#++

class Activity < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker


  #####################
  ### MISCEALLENOUS ###
  #####################

  set_table_name 'logs'

  serialize :data, Hash

  #################
  ### CALLBACKS ###
  #################

  # NOTE don't forget to update purge_activities rake task if
  # you apply important reworks on this model.

  #################
  ### RELATIONS ###
  #################

  belongs_to  :person
  belongs_to  :resource, polymorphic: true


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :action, :data, :resource_type, :resource_id
  validates_with PointsToModelValidator, attr: :resource_type

  # Validate fields of type 'string' length
  validates_length_of :action, maximum: 255


  ########################
  ### INSTANCE METHODS ###
  ########################

  def clear_person_id
    update_attributes(person_id: nil)
  end

  def formatted_data
    if %w{create destroy info}.include?(action)
      data.map{ |k, v| "#{k}: #{v.inspect}" }.join("\n")
    else
      data.map{ |k, a| "#{k}: #{a.map(&:inspect).join(' -> ')}" }.join("\n")
    end
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:person_name] = person.try(:name)
    h[:formatted_data] = formatted_data
    h[:errors] = errors

    h
  end

end
