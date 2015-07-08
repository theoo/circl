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

  class SalariesAndTaxes < Exporter::Resource

    def initialize(options = {})
      super

      options[:salary_prefix]       ||= ApplicationSetting.value("salaries_prefix")
      @options = options
      @options[:date] ||= Time.now.to_date

      @display_employer_part = @options.delete(:employer_part)
    end

    def desc_for(i)
      desc = ApplicationSetting.value("export_salary_and_taxes_description")
      json = validate_settings(desc, i)
      [@options[:salary_prefix], json[:attributes].map{ |a| eval("i.#{a}") }].flatten.join(json[:separator])
    end

    def default_desc(i)
      str = [ @options[:salary_prefix],
        i.person.name + "[" + i.person.id.to_s + "]",
        i.title + "[" + i.id.to_s + "]",
        i.from.strftime("%d-%m") + " - " + i.to.strftime("%d-%m") ].join("/")
    end

    def convert(salary)
      # every lines shoud have the same date
      @options[:date] = salary.created_at.to_date

      if @display_employer_part
        employer_taxes_resource = Exporter::Taxes.new(@options.merge(:employer_part => true))
      end

      employee_taxes_resource = Exporter::Taxes.new(@options)

      # the salary itself, gross pay
      salary_and_taxes = [
        {
          :id                         => salary.id,
          :date                       => @options[:date],
          :title                      => salary.title,
          :description                => desc_for(salary) + "/" + I18n.t("salary.views.gross"),
          :value                      => salary.gross_pay.to_f,
          :value_currency             => salary.gross_pay.currency.to_s,
          :account                    => salary.brut_account,
          :counterpart_account        => nil,
          :vat_code                   => nil,
          :vat_rate                   => nil,
          :person_id                  => salary.person.id,
          :person_name                => salary.person.name,
          :document_type              => :salary
        }
      ]

      # its employee taxes
      salary.tax_data.each do |t|
        salary_and_taxes << employee_taxes_resource.convert_employee_taxes(t) if t.employee_value > 0
      end

      # balance the net salary
      salary_and_taxes << {
          :id                         => salary.id,
          :date                       => @options[:date],
          :title                      => salary.title,
          :description                => desc_for(salary) + "/" + I18n.t("salary.views.net"),
          :value                      => salary.net_salary.to_f,
          :value_currency             => salary.net_salary.currency.to_s,
          :account                    => nil,
          :counterpart_account        => salary.net_account,
          :vat_code                   => @options[:salary_vat_code],
          :vat_rate                   => @options[:service_vat_rate],
          :person_id                  => salary.person.id,
          :person_name                => salary.person.name,
          :document_type              => :salary
      }

      # employer taxes if requested
      if employer_taxes_resource
        # employer account
        salary_and_taxes << {
            :id                         => salary.id,
            :date                       => @options[:date],
            :title                      => salary.title,
            :description                => desc_for(salary) + "/" + I18n.t("salary.views.employer_part"),
            :value                      => salary.employer_value_total.to_f,
            :value_currency             => salary.employer_value_total.currency.to_s,
            :account                    => salary.employer_account,
            :counterpart_account        => nil,
            :vat_code                   => @options[:salary_vat_code],
            :vat_rate                   => @options[:service_vat_rate],
            :person_id                  => salary.person.id,
            :person_name                => salary.person.name,
            :document_type              => :salary
        }

       # balance employer taxes
        salary.tax_data.each do |t|
          salary_and_taxes << employer_taxes_resource.convert_employer_taxes(t) if t.employer_value > 0
        end
      end

      salary.untaxed_items.each do |u|
        if u.value > 0
          account  = salary.net_account
          caccount = "CHANGEME"
        else
          account  = "CHANGEME"
          caccount = salary.net_account
        end

        # append untaxed categories
        salary_and_taxes << {
            :id                         => salary.id,
            :date                       => @options[:date],
            :title                      => salary.title,
            :description                => desc_for(salary) + "/" + u.title,
            :value                      => u.value.abs.to_f,
            :value_currency             => u.value.currency.to_s,
            :account                    => account,
            :counterpart_account        => caccount,
            :vat_code                   => @options[:salary_vat_code],
            :vat_rate                   => @options[:salary_vat_rate],
            :person_id                  => salary.person.id,
            :person_name                => salary.person.name,
            :document_type              => :salary
        }
      end

      salary_and_taxes
    end
  end

end
