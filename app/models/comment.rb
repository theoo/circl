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
# Table name: comments
#
# *id*::            <tt>integer, not null, primary key</tt>
# *person_id*::     <tt>integer</tt>
# *resource_id*::   <tt>integer</tt>
# *resource_type*:: <tt>string(255)</tt>
# *title*::         <tt>string(255), default("")</tt>
# *description*::   <tt>text, default("")</tt>
# *is_closed*::     <tt>boolean, default(FALSE), not null</tt>
# *created_at*::    <tt>datetime</tt>
# *updated_at*::    <tt>datetime</tt>
#--
# == Schema Information End
#++

class Comment < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### RELATIONS ###
  #################

  belongs_to  :person
  belongs_to  :resource, polymorphic: true


  ###################
  ### VALIDATIONS ###
  ###################
  validates_presence_of :title, :description, :resource_type, :resource_id
  validates_with Validators::PointsToModel, attr: :resource_type

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536

  scope :open_comments, -> { where(is_closed: false) }


  ########################
  ### INSTANCE METHODS ###
  ########################

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:person_name] = person.try(:name)
    h[:resource_name] = resource.try(:name)
    h[:errors] = errors

    h
  end

end
