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

  class Employee < Exporter::Resource

    def initialize(options = {})
      super

      @options= { :date => Time.now.to_date }
      @options.merge(options)
    end

    def convert(person)
      {
        :person_id                  => person.id,
        :person_first_name          => person.first_name,
        :person_last_name           => person.last_name,
        :person_name                => person.full_name, # should not be an organization
        :person_phone               => person.phone,
        :person_address             => person.address,
        :person_postal_code         => person.try(:location).try(:postal_code_prefix),
        :person_city                => person.try(:location).try(:name),
        :person_country             => person.try(:location).try(:country).try(:name),
        :person_gender              => (person.gender ? "M" : "F"),
        :person_avs_number          => person.avs_number,
        :person_birth_date          => person.birth_date,
      }
    end
  end

end