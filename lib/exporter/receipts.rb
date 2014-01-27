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

  class Receipts < Exporter::Resource

    def initialize(options = {})
      super

      options[:account]             ||= ApplicationSetting.value("receipts_credit_account")
      options[:counterpart_account] ||= ApplicationSetting.value("receipts_debit_account")
      options[:receipt_vat_code]    ||= ApplicationSetting.value("receipts_vat_code")
      options[:service_vat_rate]         ||= ApplicationSetting.value("service_vat_rate")
      options[:receipt_prefix]      ||= ApplicationSetting.value("receipts_prefix")
      @options = options
    end

    def title_for(i)
      @options[:receipt_prefix] + " " + i.id.to_s
    end

    def desc_for(i)
      [ @options[:receipt_prefix], "client " + i.owner.id.to_s, "#{title_for(i)} - #{i.id}" ].join("/")
    end

    def convert(receipt)

      {
        :id                         => receipt.id,
        :date                       => receipt.value_date,
        :title                      => title_for(receipt),
        :description                => desc_for(receipt),
        :value                      => receipt.value.to_view,
        :value_currency             => receipt.value.try(:currency).try(:to_s),
        :account                    => @options[:account],
        :counterpart_account        => @options[:counterpart_account],
        :vat_code                   => @options[:receipt_vat_code],
        :vat_rate                   => @options[:service_vat_rate],
        :person_id                  => receipt.owner.id,
        :person_name                => receipt.owner.name,
        :document_type              => :receipt
      }

    end
  end

end