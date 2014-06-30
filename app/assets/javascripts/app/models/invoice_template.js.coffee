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

class App.InvoiceTemplate extends Spine.Model

  @configure 'InvoiceTemplate', 'title', 'html', 'with_bvr', 'show_invoice_value',
              'bvr_address', 'bvr_account', 'thumb_url', 'language_id', 'account_identification'

  @extend Spine.Model.Ajax
  @extend Spine.Extensions.RemoteCount

  @url: ->
    "#{Spine.Model.host}/settings/invoice_templates"

  constructor: ->
    super
