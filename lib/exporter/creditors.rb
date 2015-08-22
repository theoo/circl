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

  class Creditors < Exporter::Resource

    def initialize(options = {})
      super

      options[:creditor_vat_code]   ||= ApplicationSetting.value("creditor_vat_code")
      options[:service_vat_rate]    ||= ApplicationSetting.value("service_vat_rate")
      options[:creditor_prefix]     ||= ApplicationSetting.value("creditor_prefix")
      @options = options
    end

    def desc_for(i)
      desc = ApplicationSetting.value("export_creditor_description")
      json = validate_settings(desc, i)
      [@options[:creditor_prefix], json[:attributes].map{ |a| eval("i.#{a}") }].flatten.join(json[:separator])
    end

    def default_desc(i)
      client_str = "Client "
      if i.owner
        client_str += i.owner.try(:id).try(:to_s)
      else
        client_str += "missing!"
      end
      creditor_str = "#{i.title} - #{i.id}"
      [ @options[:creditor_prefix], client_str, creditor_str ].join("/")
    end

    def convert(creditor)
      if not creditor.invoice_in_books_on.nil?
        counterpart_account = creditor.creditor.try(:creditor_transitional_account)
        account = creditor.creditor.try(:creditor_account)
      else
        counterpart_account = ApplicationSetting.value("creditor_account")
        account = creditor.creditor.try(:creditor_transitional_account)
      end

      {
        :id                         => creditor.id,
        :date                       => creditor.created_at.to_date,
        :title                      => creditor.title,
        :description                => desc_for(creditor),
        :value                      => creditor.value_with_taxes.to_f,
        :value_currency             => creditor.value_currency,
        :account                    => account,
        :counterpart_account        => counterpart_account,
        :vat_code                   => @options[:creditor_vat_code],
        :vat_rate                   => @options[:service_vat_rate],
        :person_id                  => creditor.creditor.try(:id),
        :person_name                => creditor.creditor.try(:name),
        :document_type              => :creditor
      }

    end
  end

end