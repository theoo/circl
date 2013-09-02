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

Person = App.Person
PersonAffairReceipt = App.PersonAffairReceipt
PersonAffairInvoice = App.PersonAffairInvoice

$.fn.receipt = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonAffairReceipt.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    @person_id = params.person_id if params.person_id
    @affair_id = params.affair_id if params.affair_id
    super

  active: (params) ->
    @invoice = params.invoice if params.invoice
    @render()

  render: =>
    @show()
    @receipt = new PersonAffairReceipt(value: 0)
    @receipt.means_of_payment = 'CCP'
    if @invoice
      @receipt.value = @invoice.value
      @receipt.invoice_id = @invoice.id
      @receipt.invoice_title = @invoice.title
    @html @view('people/affairs/receipts/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @receipt.fromForm(e.target), =>
      PersonAffairInvoice.fetch()
      @render()

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    @person_id = params.person_id if params.person_id
    @affair_id = params.affair_id if params.affair_id
    super

  active: (params) ->
    @id = params.id if params.id
    @show()
    @render()

  render: =>
    return unless PersonAffairReceipt.exists(@id)
    @receipt = PersonAffairReceipt.find(@id)
    @html @view('people/affairs/receipts/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @receipt.fromForm(e.target)
    @save_with_notifications @receipt, =>
      PersonAffairInvoice.fetch()
      @hide()

class Index extends App.ExtendedController
  events:
    'receipt-edit':    'edit'
    'receipt-destroy': 'destroy'

  constructor: (params) ->
    super
    PersonAffairReceipt.bind('refresh', @render)

  active: (params) ->
    @render()

  render: =>
    @receipts = PersonAffairReceipt.all()
    @html @view('people/affairs/receipts/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    receipt = $(e.target).receipt()
    @trigger 'edit', receipt.id

  destroy: (e) ->
    receipt = $(e.target).receipt()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications receipt

class Header extends Spine.Controller

  constructor: (params) ->
    super
    PersonAffairReceipt.bind('refresh', @render)

  render: =>
    @html @view('people/affairs/receipts/header')(@)
    Ui.load_ui(@el)

class App.PersonAffairReceipts extends Spine.Controller
  className: 'receipts'

  constructor: (params) ->
    super

    @person_id = params.person_id
    @affair_id = params.affair_id

    PersonAffairReceipt.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@affair_id}/receipts"

    @header = new Header
    @index = new Index
    @edit = new Edit(person_id: @person_id, affair_id: @affair_id)
    @new = new New(person_id: @person_id, affair_id: @affair_id)
    @append(@header, @new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    PersonAffairReceipt.refresh([], clear: true)
    PersonAffairReceipt.fetch()
    @edit.hide()
    @new.render()
    @header.render()
