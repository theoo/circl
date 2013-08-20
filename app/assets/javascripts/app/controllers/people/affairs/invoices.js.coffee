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

$ = jQuery.sub()
Person = App.Person
Affair = App.Affair
PersonAffairInvoice = App.PersonAffairInvoice
PersonAffairReceipt = App.PersonAffairReceipt
Permissions = App.Permissions
InvoiceTemplate = App.InvoiceTemplate

$.fn.invoice = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonAffairInvoice.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    @person_id = params.person_id if params.person_id
    @affair_id = params.affair_id if params.affair_id
    Person.bind('refresh', @render)
    Affair.bind('refresh', @render)
    InvoiceTemplate.bind('refresh', @render)
    super

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    unless @can?.invoice.create && Person.exists(@person_id) && Affair.exists(@affair_id)
      @hide()
      return
    @person = Person.find(@person_id)
    @affair = Affair.find(@affair_id)
    @invoice = new PersonAffairInvoice(value: 0)
    @invoice.printed_address = @person.address_for_bvr
    @invoice.title = @affair.title
    @invoice.description = @affair.description
    @invoice.value = @affair.value
    @invoice.created_at = (new Date).to_view()
    @show()
    @html @view('people/affairs/invoices/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @invoice.fromForm(e.target)
    @save_with_notifications @invoice, @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  active: (params) ->
    @can = params.can if params.can
    @id = params.id if params.id
    @show()
    @render()

  render: =>
    return unless PersonAffairInvoice.exists(@id) && @can
    unless @can.invoice.create
      @hide()
      return
    @invoice = PersonAffairInvoice.find(@id)
    @html @view('people/affairs/invoices/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @invoice.fromForm(e.target)
    @save_with_notifications @invoice, @hide

class Index extends App.ExtendedController
  events:
    'invoice-edit':    'edit'
    'invoice-pdf':     'pdf'
    'invoice-preview': 'preview'
    'invoice-destroy': 'destroy'
    'receipt-add':     'add_receipt'

  constructor: (params) ->
    super
    PersonAffairInvoice.bind('refresh', @render)
    InvoiceTemplate.bind('refresh', @render)

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    @invoices = PersonAffairInvoice.all()
    @html @view('people/affairs/invoices/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    invoice = $(e.target).invoice()
    @trigger 'edit', invoice.id

  pdf: (e) ->
    invoice = $(e.target).invoice()
    window.location = "#{PersonAffairInvoice.url()}/#{invoice.id}.pdf"

  preview: (e) ->
    invoice = $(e.target).invoice()
    win = Ui.stack_window('preview-invoice', {width: 900, height: $(window).height(), remove_on_close: true})
    $(win).dialog({title: I18n.t('invoice.views.contextmenu.preview_pdf')})
    iframe = $("<iframe src='" +
                "#{PersonAffairInvoice.url()}/#{invoice.id}.html" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    $(win).html iframe
    $(win).dialog('open')

  destroy: (e) ->
    invoice = $(e.target).invoice()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications invoice

  add_receipt: (e) ->
    invoice = $(e.target).invoice()
    @trigger 'receipt-add', invoice

class Header extends Spine.Controller

  constructor: (params) ->
    super
    PersonAffairInvoice.bind('refresh', @render)

  render: =>
    @html @view('people/affairs/invoices/header')(@)
    Ui.load_ui(@el)

class App.PersonAffairInvoices extends Spine.Controller
  className: 'invoices'

  constructor: (params) ->
    super

    @person_id = params.person_id
    @affair_id = params.affair_id

    PersonAffairInvoice.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@affair_id}/invoices"

    @header = new Header
    @index = new Index
    @edit = new Edit
    @new = new New(person_id: @person_id, affair_id: @affair_id)
    @append(@header, @new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    Person.fetch(id: @person_id)
    Affair.fetch(id: @affair_id)
    PersonAffairInvoice.refresh([], clear: true)
    PersonAffairInvoice.fetch()
    InvoiceTemplate.fetch()
    Permissions.get { person_id: @person_id, can: { invoice: ['create', 'update'] }}, (data) =>
                                                         @edit.active {can: data}
                                                         @edit.hide()
                                                         @new.active {person_id: @person_id, can: data}
                                                         @index.active {can: data}
    @edit.hide()
    @new.render()
    @header.render()
