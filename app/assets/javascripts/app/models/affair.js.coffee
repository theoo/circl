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

class App.Affair extends Spine.Model

  @configure 'Affair', 'id', 'owner_id', 'owner_name', 'buyer_id', 'buyer_name', 'receiver_id', 'receiver_name',
             'title', 'description', 'value', 'invoices_count', 'invoices_value', 'receipts_value', 'created_at'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/admin/affairs"

  constructor: ->
    super

  @fetch_statuses: ->
    get_callback = (data) =>
      @_statuses = data
      @trigger "statuses_fetched"

    $.get(@url() + "/available_statuses", get_callback, 'json')

  @statuses: ->
    @_statuses if @_statuses
