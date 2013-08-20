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

class App.PersonAffairInvoicesAndReceipts extends Spine.Controller
  className: 'invoices_and_receipts'

  constructor: (params) ->
    super

    @person_id = params.person_id
    @affair_id = params.affair_id

    common_style = 'width: 45%; overflow: auto; padding: 5px;'
    $(@el).html("<div style='float: left; #{common_style}'></div><div style='float: right; #{common_style}'></div>")
    [invoices_container, receipts_container] = $(@el).find('div')

    @invoices = new App.PersonAffairInvoices({el: invoices_container, person_id: @person_id, affair_id: @affair_id})
    @receipts = new App.PersonAffairReceipts({el: receipts_container, person_id: @person_id, affair_id: @affair_id})

    @invoices.index.bind 'receipt-add', (invoice) =>
      @receipts.new.active { invoice: invoice }

  activate: ->
    super
    @invoices.activate()
    @receipts.activate()
