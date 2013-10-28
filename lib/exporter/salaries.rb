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

  class Salaries < Exporter::Resource

    def initialize(options = {})
      super
      @options = options
    end

    def convert(salary)
      {
        :id                       => salary.id,
        :date                     => @options[:date],
        :created_at               => salary.created_at.strftime("%d.%m.%Y"), # Format for elohnausweisssk
        :from                     => salary.from,
        :to                       => salary.to,
        :title                    => salary.title,
        :yearly_salary            => salary.reference.yearly_salary.to_f,
        :value                    => salary.gross_pay.to_f,
        :gross_pay                => salary.gross_pay.to_f,
        :employee_value_total     => salary.employee_value_total.to_f,
        :employer_value_total     => salary.employer_value_total.to_f,
        :net_pay                  => salary.net_salary.to_f,
        :value_currency           => salary.gross_pay.currency.to_s,
        :account                  => salary.brut_account,
        :counterpart_account      => nil,
        :gross_account             => salary.brut_account,
        :net_account              => salary.net_account,
        :vat_code                 => nil,
        :vat_rate                 => nil,
        :person_id                => salary.person.id,
        :person_name              => salary.person.name,
        :person_gender            => salary.person.gender,
        :person_phone             => salary.person.phone,
        :person_birth_date        => salary.person.birth_date,
        :person_email             => salary.person.email,
        :person_address           => salary.person.address,
        :person_bank_informations => salary.person.bank_informations,
        :person_avs_number        => salary.person.avs_number,
        :document_type            => :salary
      }
    end
  end

end