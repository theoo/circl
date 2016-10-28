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
# Table name: roles
#
# *id*::          <tt>integer, not null, primary key</tt>
# *name*::        <tt>string(255), default("")</tt>
# *description*:: <tt>text, default("")</tt>
# *created_at*::  <tt>datetime</tt>
# *updated_at*::  <tt>datetime</tt>
#--
# == Schema Information End
#++

class Role < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### CALLBACKS ###
  #################

  before_destroy :check_for_associated_people

  #################
  ### RELATIONS ###
  #################

  has_many  :permissions, dependent: :destroy

  has_many  :people_roles # for permissions
  has_many  :people,
            -> { distinct },
            class_name: 'Person',
            through: :people_roles,
            after_add: :update_elasticsearch_index,
            after_remove: :update_elasticsearch_index

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_uniqueness_of :name

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536


  ########################
  ### INSTANCE METHODS ###
  ########################

  def set_all_permissions!
    # reset permissions beforhands to ensure role have full access
    reset_permissions!

    # set all available permissions to this role
    perms = Permission.get_available_permissions.each do |p|
      attrs = p.attributes
      attrs.delete("id")
      attrs["role_id"] = self.id
      Permission.create(attrs)
    end
  end

  def reset_permissions!
    permissions.each{|p| p.destroy}
    permissions = []
    # or this self requires a reload
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:permissions_count] = permissions.count
    h[:members_count]     = people.count
    h[:errors]            = errors

    h
  end


  protected

  # on destroy, abort if there people associated to role
  def check_for_associated_people
    unless people.empty?
      errors.add(:base, I18n.t('role.errors.cant_delete_if_in_use'))
      false
    end
  end

end
