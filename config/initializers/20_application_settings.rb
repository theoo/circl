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

# Ensure all required key exists in ApplicationSetting
extend ColorizedOutput

mandatory_fields = [:application_id,
                    :mailchimp_list_name,
                    :mailchimp_api_key,
                    :mailchimp_connection_secure,
                    :mailchimp_connection_timeout,
                    :invoices_prefix,
                    :invoices_debit_account,
                    :invoices_credit_account,
                    :invoices_vat_code,
                    :invoices_vat_rate,
                    :receipts_prefix,
                    :receipts_debit_account,
                    :receipts_credit_account,
                    :receipts_vat_code,
                    :receipts_vat_rate,
                    :default_locale]

# Table may not exist on rake db:schema:load
if ActiveRecord::Base.connection.table_exists? 'application_settings' \
    and ENV['force_application_settings'] != 'true' \
    and Rails.env != 'test'

  print "Verifing ApplicationSettings: "

  if ApplicationSetting.count > 0
    mandatory_fields.each do |mf|
      if ApplicationSetting.where(:key => mf.to_s).count != 1
        message = "Application settings are not set proprely for environnement '#{Rails.env}'. "
        message << "Ensure key '#{mf}' is present (#{ApplicationSetting.where(:key => mf.to_s).count}) "
        message << "or run rake db:seed:application_settings:reset and readjust values."

        raise ArgumentError, message
      end
    end
  end

  puts green("done") + "."
end