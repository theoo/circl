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

  # include ChangesTracker

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :key
  validates_uniqueness_of :key
  validate :ensure_key_is_unchanged, unless: :new_record?

  # Validate fields of type 'string' length
  validates_length_of :key, maximum: 255

  validate :value_matches_type

  #####################
  ### CLASS METHODS ###
  #####################

  class << self
    def value(key, options = {:silent => false})

      if Rails.configuration.try :application_settings
        # Variable way, faster
        setting = Rails.configuration.application_settings[key.to_sym]
        puts setting.inspect

        if setting
          convert_value(*setting)
        elsif ! options[:silent]
          msg = "ApplicationSetting key '#{key}' is missing."
          logger.warn msg
          raise MissingAttribute, msg
        end
      else
        # AREL way, slow
        begin
          return false unless ActiveRecord::Base.connection.table_exists? 'application_settings'
        rescue ActiveRecord::NoDatabaseError
          return false
        end

        setting = where(:key => key).first
        if setting
          convert_value(setting.value, setting.type_for_validation)
        elsif ! options[:silent]
          msg = "ApplicationSetting key '#{key}' is missing."
          logger.warn msg
          raise MissingAttribute, msg
        end
      end
    end

    # NOTE Mandatory fields are not defined in the database (non sense)
    def mandatory_fields
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
      :default_locale,
      :me,
      :default_currency,
      :use_vat]
    end

    private

      def convert_value(val, type = 'string')
        case type
          when 'time'    then eval(val)
          when 'boolean' then !!(['True', 'true', 't', '1'].index val)
          when 'integer' then val.to_i
          when 'float'   then val.to_f
          when 'string'  then val
          when 'url'     then val
          when 'email'   then val
          else "unknown type"
        end
      end

  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:errors] = errors

    h
  end

  def type_for_validation_format_translation
    # i18n-tasks-use I18n.t("application_settings.formats.boolean")
    # i18n-tasks-use I18n.t("application_settings.formats.email")
    # i18n-tasks-use I18n.t("application_settings.formats.float")
    # i18n-tasks-use I18n.t("application_settings.formats.integer")
    # i18n-tasks-use I18n.t("application_settings.formats.string")
    # i18n-tasks-use I18n.t("application_settings.formats.time")
    # i18n-tasks-use I18n.t("application_settings.formats.url")
    I18n.t("application_settings.formats." + self.type_for_validation)
  end

  protected

    def ensure_key_is_unchanged
      if changes.include?(:key)
        errors.add(:key, I18n.t('application_setting.errors.cant_change_key'))
        false
      end
    end

  private

    def value_matches_type
      regex = {
        boolean: /^(True|true|t|1|False|false|f|0)$/,
        email: /^[a-z0-9!#$%&'*+\/=?^_`{|}~.-]+@[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/i,
        float: /^\s*(\-|\+)?(\d+|(\d*(\.\d*)))\s*$/,
        integer: /^\d+$/,
        string: /.*/, # no validations
        time: /^\d+.(second|minute|hour|day|week|month|year)s?$/,
        url: /^(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?$/,
      }

      unless value.to_s.match(regex[type_for_validation.to_sym])
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_boolean")
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_email")
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_float")
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_integer")
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_string")
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_time")
        # i18n-tasks-use I18n.t("application_settings.errors.value_should_be_url")

        errors.add :value, I18n.t("application_settings.errors.value_should_be_#{type_for_validation}")
        return false
      end

  end
end
