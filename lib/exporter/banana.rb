# encoding: utf-8
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

module Exporter

  class Banana < Base

    def initialize(resource)
      super
      @csv_options[:col_sep] = "\t"

      @mapping = ApplicationSetting.value("banana_accounting_headers_mapping", :silent => true)
      if @mapping
        begin
          # symbolize_values
          h = JSON.parse(@mapping)
          @mapping = {}
          h.each do |k,v|
            # Keep empty string if this is what user wants.
            @mapping[k] = v == "" ? v : v.to_sym
          end
        rescue
          @mapping = {:document_type => 'Configuration value error !'}
        end
        @cols = @mapping.values if @mapping
      end

      # Defaults
      @cols ||= [:date, :description, :account, :counterpart_account, :value, :vat_code, :vat_rate]
    end

    def headers
      # XML name following to the doc: http://www.banana.ch/cms/fr/node/3850

      if @mapping
        # ApplicationSettings
        @mapping.keys
      else
        # Defaults
        ["Date", "Description", "AccountDebit", "AccountCredit", "Amount", "VatCode", "VatPercentNonDeductible"]
      end
    end

    # override map_item to convert dates
    # FIXME: this should be global in application_settings
    def map_item(i)
      validate_requirements i, @cols

      @cols.map do |c|
        if i[c].is_a? Date
          i[c].strftime("%Y-%m-%d")
        else
          i[c]
        end
      end
    end

  end

end
