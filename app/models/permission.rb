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
# Table name: permissions
#
# *id*::              <tt>integer, not null, primary key</tt>
# *role_id*::         <tt>integer</tt>
# *action*::          <tt>string(255), default("")</tt>
# *subject*::         <tt>string(255), default("")</tt>
# *hash_conditions*:: <tt>text</tt>
# *created_at*::      <tt>datetime</tt>
# *updated_at*::      <tt>datetime</tt>
#--
# == Schema Information End
#++

class Permission < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include Reflection

  #################
  ### RELATIONS ###
  #################

  belongs_to  :role


  ###################
  ### VALIDATIONS ###
  ###################
  validates_presence_of :action, :subject, :role_id

  validate :subject_is_model, if: :has_conditions?
  validate :has_valid_conditions, if: :has_conditions?

  # Validate fields of type 'string' length
  validates_length_of :action, maximum: 255
  validates_length_of :subject, maximum: 255


  ########################
  ### INSTANCE METHODS ###
  ########################

  def has_conditions?
    hash_conditions.present?
  end

  def cancan_subject
    begin
      subject.constantize
    rescue
      logger.warn "Permission: caught exception while constantizing #{subject}" if Rails.env == "development"
      subject
    end
  end

  def as_string
    "#{subject}##{action}"
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    # add relation description to save a request
    h[:role_name] = role.try(:name)

    # add errors if any
    h[:errors] = errors # unless errors.empty?
    h
  end

  # Retrieves all permissions from database and custom_actions file,
  # and return an array of readonly Permission
  def self.get_available_permissions
    # retrieve all contollers/actions from Rails itself
    rails_actions = PermissionsList.as_hash
    rails_actions = rails_actions.each_with_object({}) do |(controller, actions), h|
      h[controller.constantize.model] = actions
    end

    # merge with actions found in config/configuration.yml
    Rails.configuration.settings['permissions'].each do |model, actions|
      rails_actions[model.constantize] ||= []
      rails_actions[model.constantize] += actions.map(&:to_sym)
    end

    # make a array of readonly Permission objects
    all_permissions = permissionize(rails_actions)
    all_permissions.sort_by(&:as_string)
  end

  # Build an array of readonly Permission based on the hash "h"
  # Hash structure should be Model => [action1, action2, ...]
  def self.permissionize(h)
    h.each_with_object([]) do |(model, actions), arr|
      actions.each do |action|
        p = Permission.new(action: action, subject: model.to_s)
        p.readonly!
        arr << p
      end
    end
  end


  protected

  def subject_is_model
    unless subject_is_a_model_name?
      errors.add(:subject, I18n.t('permission.errors.subject_must_point_to_model_if_condition_present'))
      false
    end
  end

  def has_valid_conditions
    user = subject.constantize.new
    begin
      eval(hash_conditions)
    rescue Exception
      errors.add(:hash_conditions, I18n.t('permission.errors.condition_does_not_evaluate'))
      false
    end
  end

  def subject_is_a_model_name?
    list_model_names.include?(subject) || subject == 'ActsAsTaggableOn::Tag'
  end
end
