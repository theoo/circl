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

  class Taxes < Exporter::Resource

    def initialize(options = {})
      super

      options[:employee_deductions_prefix] ||= ApplicationSetting.value("salaries_employee_deductions_prefix")
      options[:employer_deductions_prefix] ||= ApplicationSetting.value("salaries_employer_deductions_prefix")
      @options = options
    end

    def convert(items)
      raise NotImplementedError, 'No generic convert, use convert_employee_taxes and convert_employer_taxes instead.'
    end

    def employee_desc_for(t)
      i = t.salary
      [ @options[:employee_deductions_prefix],
        i.person.name + "[" + i.person.id.to_s + "]",
        i.title + "[" + i.id.to_s + "]",
        i.from.strftime("%d-%m") + " - " + i.to.strftime("%d-%m"),
        t.tax.title ].join("/")
    end

    def employer_desc_for(t)
      i = t.salary
      [ @options[:employer_deductions_prefix],
        i.person.name + "[" + i.person.id.to_s + "]",
        i.title + "[" + i.id.to_s + "]",
        i.from.strftime("%d-%m") + " - " + i.to.strftime("%d-%m"),
        t.tax.title ].join("/")
    end

    def convert_employee_taxes(tax)
      {
        :id                         => tax.id,
        :date                       => @options[:date],
        :title                      => tax.tax.title,
        :description                => employee_desc_for(tax),
        :value                      => tax.employee_value.to_f,
        :value_currency             => tax.employee_value.to_money.currency.to_s,
        :account                    => nil,
        :counterpart_account        => tax.tax.employee_account,
        :vat_code                   => nil,
        :vat_rate                   => nil,
        :person_id                  => tax.salary.person.id,
        :person_name                => tax.salary.person.name,
        :document_type              => :tax,
        :cost_center_1              => nil
      }
    end

    def convert_employer_taxes(tax)
      {
        :id                         => tax.id,
        :date                       => @options[:date],
        :title                      => tax.tax.title,
        :description                => employer_desc_for(tax),
        :value                      => tax.employer_value.to_f,
        :value_currency             => tax.employer_value.to_money.currency.to_s,
        :account                    => nil,
        :counterpart_account        => tax.tax.employer_account,
        :vat_code                   => nil,
        :vat_rate                   => nil,
        :person_id                  => tax.salary.person.id,
        :person_name                => tax.salary.person.name,
        :document_type              => :tax,
        :cost_center_1              => nil
      }
    end

  end

end