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

  class Ocas < Base

    def initialize(resource)
      super
      @csv_options[:col_sep] = ";"

      @circl_owner = Person.find ApplicationSetting.value(:me)
      @employee_cols = [:person_avs_number,
                        :person_name,
                        :person_birth_date,
                        :person_gender]

      @certificate_cols = [ :cert_from,
                            :cert_to ]

    end

    # override map_item to convert dates
    def map_item(i, cols)
      validate_requirements i, cols

      cols.map do |c|
        if c.is_a? Symbol
          if i[c].is_a? Date
            i[c].strftime("%d.%m.%Y")
          else
            i[c]
          end
        else
          c
        end
      end
    end

    def export(salaries)
      ## the ruby way
      # deduction_names = employee_salaries.map do |salary|
      #   salary.items.map{ |i| i.taxes.map(&:title) }
      # end.flatten.uniq

      # sql way aka "sado-masochism"
      @deduction_cols = salaries
        .joins('INNER JOIN salaries_items ON salaries_items.salary_id = salaries.id')
        .joins('INNER JOIN salaries_items_taxes ON salaries_items_taxes.item_id = salaries_items.id')
        .joins('INNER JOIN salaries_taxes ON salaries_taxes.id = salaries_items_taxes.tax_id')
        .select('DISTINCT salaries_taxes.title')
        .map(&:title)

      CSV.generate(@csv_options) do |csv|

        # remplace the 'headers' method
        csv << [@employee_cols, @certificate_cols, @deduction_cols].flatten

        employee_resource = Exporter::Employee.new
        cert_resource = Exporter::SalaryCertificate.new

        # map people referenced in salaries
        @employees = salaries.all.map(&:person).uniq

        # append employees to CSV file
        @employees.each do |employee|
          e = employee_resource.convert(employee)
          line = map_item(e, @employee_cols)

          employee_salaries = salaries.where(:person_id => employee.id)
          c = cert_resource.convert(employee_salaries)
          line << map_item(c, @certificate_cols)

          # add sum of all reference values for all taxes
          deductions = {}
          @deduction_cols.each do |ded|
            line << employee_salaries.map { |s| s.tax(ded) ? s.tax(ded).reference_value.to_money : 0.to_money }.sum()
          end

          csv << line.flatten
        end

      end

    end

  end

end
