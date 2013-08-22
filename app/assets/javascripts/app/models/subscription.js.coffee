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

class App.Subscription extends Spine.Model

  @configure 'Subscription', 'id', 'parent_id', 'parent_title', 'invoice_template_id', 'title', 'description',
    'invoices_count', 'invoices_value','receipts_count', 'receipts_value', 'overpaid_value'
    'interval_starts_on', 'interval_ends_on', 'values', 'value_currency',
    'created_at', 'status'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/admin/subscriptions"

  members_count: 0

  constructor: ->
    super

  validate: ->
    e = new App.ErrorsList

    return e unless e.is_empty()
