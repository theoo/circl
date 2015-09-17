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

      options[:service_vat_rate]    ||= ApplicationSetting.value("service_vat_rate")
      @options = options
    end

    def desc_for(i, prefix)
      desc = ApplicationSetting.value("export_creditor_description")
      json = validate_settings(desc, i)
      [prefix, json[:attributes].map{ |a| eval("i.#{a}") }].flatten.join(json[:separator])
    end

    def default_desc(i)
      creditor_str = "#{i.title} - #{i.id}"
      [ @options[:creditor_prefix], creditor_str ].join("/")
    end

    def convert(creditor)
      lines = []

      bank_account = ApplicationSetting.value("creditor_paid_account")
      cc1 = creditor.affair_id.to_s

      # Check which step it is, exporting invoices or payments
      if not creditor.paid_on.blank?
        # It's a payment

        # creditor_paid_account is usually the bank
        prefix = ApplicationSetting.value("creditor_paid_prefix")
        date = creditor.paid_on
        counterpart_account = ApplicationSetting.value("creditor_paid_account")
        account = creditor.transitional_account

        # Invert account when negative
        if creditor.value_with_discount < 0
          old_account = account
          counterpart_account = counterpart_account
          account = old_account
        end

        lines << {
          :id                         => creditor.id,
          :date                       => date,
          :title                      => creditor.title,
          :description                => desc_for(creditor, prefix),
          :value                      => creditor.value_with_discount.abs.to_f,
          :value_currency             => creditor.value_currency,
          :account                    => account,
          :counterpart_account        => counterpart_account,
          :vat_code                   => nil,
          :vat_rate                   => nil,
          :person_id                  => creditor.creditor.try(:id),
          :person_name                => creditor.creditor.try(:name),
          :document_type              => :creditor,
          :cost_center_1              => nil
        }

        # return discount to account if existing
        if creditor.discount_percentage > 0 and creditor.discount_paid_ontime?

          account = bank_account
          counterpart_account = creditor.discount_account

          # Invert account when negative
          if creditor.value_with_discount < 0
            old_account = account
            account = counterpart_account
            counterpart_account = old_account
            cc1 = "creditor.affair_id"
          else
            cc1 = "-#{creditor.affair_id}"
          end

          lines << {
            :id                         => creditor.id,
            :date                       => date,
            :title                      => creditor.title,
            :description                => desc_for(creditor, ApplicationSetting.value("creditor_discount_prefix")),
            :value                      => creditor.discount_value.abs.to_f,
            :value_currency             => creditor.value_currency,
            :account                    => account,
            :counterpart_account        => counterpart_account,
            :vat_code                   => creditor.vat_discount_account,
            :vat_rate                   => @options[:service_vat_rate],
            :person_id                  => creditor.creditor.try(:id),
            :person_name                => creditor.creditor.try(:name),
            :document_type              => :creditor,
            :cost_center_1              => cc1
          }
        end

      else
        # It's an unpaid invoice
        prefix = ApplicationSetting.value("creditor_prefix")
        date = creditor.invoice_received_on
        counterpart_account = creditor.transitional_account
        account = creditor.account

        # Invert account when negative
        if creditor.value_with_taxes < 0
          old_account = account
          account = counterpart_account
          counterpart_account = old_account
          cc1 = "-#{cc1}"
        end

        lines << {
          :id                         => creditor.id,
          :date                       => date,
          :title                      => creditor.title,
          :description                => desc_for(creditor, prefix),
          :value                      => creditor.value_with_taxes.abs.to_f,
          :value_currency             => creditor.value_currency,
          :account                    => account,
          :counterpart_account        => counterpart_account,
          :vat_code                   => creditor.creditor.try(:creditor_vat_account),
          :vat_rate                   => @options[:service_vat_rate],
          :person_id                  => creditor.creditor.try(:id),
          :person_name                => creditor.creditor.try(:name),
          :document_type              => :creditor,
          :cost_center_1              => cc1
        }

      end

      lines
    end
  end

end