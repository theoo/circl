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
# Table name: application_settings
#
# *id*::    <tt>integer, not null, primary key</tt>
# *key*::   <tt>string(255), default("")</tt>
# *value*:: <tt>string(255), default("")</tt>
#--
# == Schema Information End
#++

class ApplicationSetting < ActiveRecord::Base

  # Custom error caught in application_controller
  class MissingAttribute < StandardError; end

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :key, :value
  validates_uniqueness_of :key
  validate :ensure_key_is_unchanged, :unless => :new_record?
  validate :ensure_value_is_not_too_long

  # Validate fields of type 'string' length
  validates_length_of :key, :maximum => 255
  validates_length_of :value, :maximum => 255


  #####################
  ### CLASS METHODS ###
  #####################

  def self.value(key)
    setting = find(:first, :conditions => {:key => key})
    if setting
      setting.value
    else
      msg = I18n.t("application_setting.errors.missing_attribute", :key => key)
      logger.warn msg
      raise MissingAttribute, msg
    end
  end


  protected

  def ensure_key_is_unchanged
    if changes.include?(:key)
      errors.add(:key, I18n.t('application_setting.errors.cant_change_key'))
      false
    end
  end

  def ensure_value_is_not_too_long
    if value && value.length > 255
      errors.add(:key, I18n.t('application_setting.errors.value_is_too_long'))
      false
    end
  end

end
