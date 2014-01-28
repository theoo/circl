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

  validates_presence_of :key
  validates_uniqueness_of :key
  validate :ensure_key_is_unchanged, :unless => :new_record?

  # Validate fields of type 'string' length
  validates_length_of :key, :maximum => 255
  # value is a text field: length unlimited says postgresql...
  validate :length_of_value_if_mandatory

  #####################
  ### CLASS METHODS ###
  #####################

  def self.value(key, options = {:silent => false})
    setting = find(:first, :conditions => {:key => key})
    if setting
      setting.value
    elsif ! options[:silent]
      msg = I18n.t("application_setting.errors.missing_attribute", :key => key)
      logger.warn msg
      raise MissingAttribute, msg
    end
  end

  # NOTE Mandatory fields are not defined in the database (non sense)
  def self.mandatory_fields
    [:application_id,
    :mailchimp_list_name,
    :mailchimp_api_key,
    :mailchimp_connection_secure,
    :mailchimp_connection_timeout,
    :invoices_prefix,
    :invoices_debit_account,
    :invoices_credit_account,
    :receipts_prefix,
    :receipts_debit_account,
    :receipts_credit_account,
    :default_locale]
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:errors] = errors

    h
  end

  protected

  def ensure_key_is_unchanged
    if changes.include?(:key)
      errors.add(:key, I18n.t('application_setting.errors.cant_change_key'))
      false
    end
  end

  def length_of_value_if_mandatory
    if self.class.mandatory_fields.index(self.key.to_sym) and value.blank?
      errors.add(:value, I18n.t("activerecord.errors.messages.blank"))
      false
    end
  end

end
