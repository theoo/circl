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

  class Invoices < Exporter::Resource

    def initialize(options = {})
      super

      options[:account]             ||= ApplicationSetting.value("invoices_credit_account")
      options[:counterpart_account] ||= ApplicationSetting.value("invoices_debit_account")
      options[:invoice_vat_code]    ||= ApplicationSetting.value("invoices_vat_code")
      options[:invoice_vat_rate]    ||= ApplicationSetting.value("invoices_vat_rate")
      options[:invoice_prefix]      ||= ApplicationSetting.value("invoices_prefix")
      @options = options
    end

    def desc_for(i)
      [ @options[:invoice_prefix], "Client " + i.owner.id.to_s, "#{i.title} - #{i.id}" ].join("/")
    end

    def convert(invoice)

      {
        :id                         => invoice.id,
        :date                       => invoice.created_at,
        :title                      => invoice.title,
        :description                => desc_for(invoice),
        :value                      => invoice.value,
        :value_currency             => invoice.value_currency,
        :account                    => @options[:account],
        :counterpart_account        => @options[:counterpart_account],
        :vat_code                   => @options[:invoice_vat_code],
        :vat_rate                   => @options[:invoice_vat_rate],
        :person_id                  => invoice.owner.id,
        :person_name                => invoice.owner.name,
        :document_type              => :invoice
      }

    end
  end

end