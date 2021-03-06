#  CIRCL Directory
#  Copyright (C) 2011 Complex IT sàrl
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class App.Creditor extends Spine.Model

  @configure 'Creditor', 'creditor_id', 'affair_id', 'title', 'description', 'value', 'value_currency',
  'vat', 'vat_currency', 'invoice_received_on', 'invoice_ends_on', 'invoice_in_books_on',
  'discount_percentage', 'discount_ends_on', 'paid_on', 'payment_in_books_on', 'vat_percentage',
  'custom_value_with_taxes', 'account', 'transitional_account', 'discount_account', 'vat_account',
  'vat_discount_account'

  @extend Spine.Model.Ajax

  @url: ->
    "#{Spine.Model.host}/admin/creditors"

  constructor: ->
    super
