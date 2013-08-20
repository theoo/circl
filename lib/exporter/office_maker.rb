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

  class OfficeMaker < Base

    def initialize(resource)
      super
      csv_options[:col_sep] = "\t"
      csv_options[:row_sep] = "\r\n"

      @cols = [:date, :description, nil, 1, :account, :counterpart_account, :value]
    end

    def headers
      # OM doesn't like headers
      # ["Date", "Libellé", "No pièce", "Code journal", "No Compte", "No Contrepartie", "Montant"]
    end

  end

end
