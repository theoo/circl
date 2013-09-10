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
PersonAffair = App.PersonAffair
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
    #Person.bind('refresh', @render)
    # PersonAffair.bind('refresh', @active)
    PersonAffairInvoice.bind('refresh', @active)
    InvoiceTemplate.bind('refresh', @active)
    super

  active: (params) =>
    @person_id = params.person_id if params.person_id
    @affair_id = params.affair_id if params.affair_id
    @can = params.can if params.can
    @render()

  render: =>
    if @can?.invoice.create && Person.exists(@person_id) && PersonAffair.exists(@affair_id)
      @person = Person.find(@person_id)
      @affair = PersonAffair.find(@affair_id)
      @invoice = new PersonAffairInvoice(value: 0)
      @invoice.printed_address = @person.address_for_bvr
      @invoice.title = @affair.title
      @invoice.description = @affair.description
      @invoice.value = @affair.value
      @invoice.created_at = (new Date).to_view()
    else
      @invoice = new PersonAffairInvoice(value: 0)

    @html @view('people/affairs/invoices/form')(@)
    Ui.load_ui(@el)
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairInvoice.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @invoice.fromForm(e.target)
    @save_with_notifications @invoice, @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'button[]':     'pdf'
    'invoice-preview': 'preview'
    'invoice-destroy': 'destroy'
    'receipt-add':     'add_receipt'

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

  pdf: (e) ->
    window.location = "#{PersonAffairInvoice.url()}/#{@invoice.id}.pdf"

  preview: (e) ->
    invoice = $(e.target).invoice()
    win = Ui.stack_window('preview-invoice', {width: 900, height: $(window).height(), remove_on_close: true})
    $(win).modal({title: I18n.t('invoice.views.contextmenu.preview_pdf')})
    iframe = $("<iframe src='" +
                "#{PersonAffairInvoice.url()}/#{invoice.id}.html" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    $(win).html iframe
    $(win).modal('show')

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @invoice

  add_receipt: (e) ->
    @trigger 'receipt-add', @invoice

class Index extends App.ExtendedController
  events:
    'click tr.item':    'edit'
    'datatable_redraw': 'table_redraw'

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

  disabled: =>
    PersonAffairInvoice.url() == undefined
    if @disabled() then @disable_panel() else @enable_panel()

  edit: (e) ->
    @invoice = $(e.target).invoice()
    @activate_in_list(e.target)
    @trigger 'edit', @invoice.id

  table_redraw: =>
    if @invoice
      target = $(@el).find("tr[data-id=#{@invoice.id}]")
    @activate_in_list(target)

class App.PersonAffairInvoices extends Spine.Controller
  className: 'invoices'

  constructor: (params) ->
    super

    # person_id and affair_id are required to build invoice template:
    # bvr address, affair value, etc.
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    # PersonAffairInvoice.url = =>
    #   "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@affair_id}/invoices"

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'error', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

    InvoiceTemplate.fetch()
    Permissions.get { person_id: @person_id, can: { invoice: ['create', 'update'] }}, (data) =>
      @edit.active {can: data}
      @edit.hide()
      @new.active { person_id: @person_id, affair_id: @affair_id, can: data }
      @index.active {can: data}

  activate: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    @new.active(person_id: @person_id, affair_id: @affair_id)
