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

  class SalaryDetails < Base

    def initialize(resource)
      super
      @cols =  [:id,
                :created_at,
                :from,
                :to,
                :title,
                :yearly_salary,
                :gross_pay,
                :employee_value_total,
                :employer_value_total,
                :net_pay,
                :gross_account,
                :net_account,
                :person_id,
                :person_name,
                :person_gender,
                :person_phone,
                :person_birth_date,
                :person_email,
                :person_address,
                :person_bank_informations,
                :person_avs_number]
    end

    def headers
      [
        "salary id",
        "creation date",
        "from",
        "to",
        "title",
        "annual salary",
        "gross salary",
        "employee total taxes",
        "exployer total taxes",
        "net salary",
        "gross account",
        "net account",
        "employee id",
        "employee name",
        "employee gender",
        "employee phone",
        "employee birth date",
        "employee email",
        "employee address",
        "employee bank information",
        "employee avs number"
      ]
    end

  end

end
