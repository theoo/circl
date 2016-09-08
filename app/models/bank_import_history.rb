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

# == Schema Information
#
# Table name: bank_import_histories
#
# *id*::             <tt>integer, not null, primary key</tt>
# *reference_line*:: <tt>string(255)</tt>
# *media_name*::     <tt>string</tt>
#--
# == Schema Information End
#++

# This class should remain simple, no relations, just a backup/log of
# previoulsy imported files/lines
class BankImportHistory < ApplicationRecord

  validates :file_name, presence: true
  validates :reference_line, uniqueness: true, presence: true
  validates :media_date, presence: true
  validates_with DateValidator, attribute: :media_date

  def decoded_line
    BankImporter::Postfinance.parse_receipt(self.reference_line)
  end

  def as_json
    h = super(options)

    # add relation description to save a request
    # h[:invoice_id] = invoice_id
    # h[:invoice_value] = invoice.try(:value).try(:to_f)
    # h[:invoice_title] = invoice.try(:title)

  end

end
