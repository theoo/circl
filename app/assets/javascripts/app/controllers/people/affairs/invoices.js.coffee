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
    super
    #Person.bind('refresh', @render)
    #PersonAffair.bind('refresh', @active)
    PersonAffairInvoice.bind('refresh', @active)
    InvoiceTemplate.bind('refresh', @active)

  active: (params) =>
    if params
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

    if @affair_id
      @affair = PersonAffair.find(@affair_id)

    @html @view('people/affairs/invoices/form')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairInvoice.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @invoice.fromForm(e.target)
    @save_with_notifications @invoice, =>
      PersonAffair.fetch()
      @render()

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="invoice-download-pdf"]': 'pdf'
    'click a[name="invoice-preview-pdf"]': 'preview'
    'click button[name="invoice-destroy"]': 'destroy'
    'click button[name="invoice-add-receipt"]': 'add_receipt'

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

    @affair = PersonAffair.find(@invoice.affair_id)

    @html @view('people/affairs/invoices/form')(@)
    # Disable destroy if invoice have receipts
    #unless @invoice.receipts_value > 0
      #destroy = $(@el).find('button[name=invoice-destroy]')
      #destroy.prop('disabled', true)
      #destroy.popover(title: 'unable',
                      #content: "asdf a asdf  fasd s dfkasdlkj a dsf sdfk",
                      #placement: 'auto bottom',
                      #trigger: 'click')

  update_callback: =>
    PersonAffair.fetch()
    PersonAffairReceipt.fetch()
    @hide()

  submit: (e) ->
    e.preventDefault()
    @invoice.fromForm(e.target)
    @save_with_notifications @invoice, @update_callback

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @invoice, @update_callback

  pdf: (e) ->
    e.preventDefault()
    window.location = "#{PersonAffairInvoice.url()}/#{@invoice.id}.pdf"

  preview: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='invoice-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.preview') + ": " + @invoice.title

    # Insert iframe to content
    iframe = $("<iframe src='" +
                "#{PersonAffairInvoice.url()}/#{@invoice.id}.html" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    win.find('.modal-body').html iframe

    # Adapt width to A4
    win.find('.modal-dialog').css(width: 900)

    # Add preview in new tab button
    btn = "<button type='button' name='invoice-preview-pdf-new-tab' class='btn btn-default'>"
    btn += I18n.t('invoice.views.actions.preview_pdf_in_new_tab')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonAffairInvoice.url()}/#{@invoice.id}.html", "_blank"

    win.modal('show')

  add_receipt: (e) ->
    e.preventDefault()
    person_affair_receipts_ctrl = $("#person_affair_receipts").data('controller')
    person_affair_receipts_ctrl.new.active
      person_id: @person_id,
      affair_id: @invoice.affair_id,
      invoice: @invoice

class Index extends App.ExtendedController
  events:
    'click tr.item':    'edit'
    'datatable_redraw': 'table_redraw'
    'mouseover tr.item':'item_over'
    'mouseout tr.item': 'item_out'

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
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairInvoice.url() == undefined

  edit: (e) ->
    @invoice = $(e.target).invoice()

    # display related receipts
    $("#person_affair_receipts").data('controller').index.render()
    @toggle_item e, true, 'success'

    # highlight in list
    @activate_in_list(e.target)

    @trigger 'edit', @invoice.id

  table_redraw: (e) =>
    if @invoice
      target = $(@el).find("tr[data-id=#{@invoice.id}]")
    @activate_in_list(target)

  item_over: (e) =>
    @toggle_item e, true

  item_out: (e) =>
    @toggle_item e, false

  toggle_item: (e, status, sclass = 'warning') =>
    invoice_id = $(e.target).invoice().id
    receipts = PersonAffairReceipt.findAllByAttribute('invoice_id', invoice_id)

    # If PersonAffairReceipt if fetched and if it matches invoice_id
    if receipts.length > 0
      $(receipts).each (index, receipt) =>
        person_affair_receipts_ctrl = $("#person_affair_receipts").data('controller')
        receipt_items = person_affair_receipts_ctrl.el.find("tr[data-id=#{receipt.id}]")

        # If there is receipts in active view
        if receipt_items.length > 0
          receipt_items.each (index, r) =>
            if status
              $(r).addClass(sclass)
            else
              $(r).removeClass(sclass)


class App.PersonAffairInvoices extends Spine.Controller
  className: 'invoices'

  constructor: (params) ->
    super

    # person_id and affair_id are required to build invoice template:
    # bvr address, affair value, etc.
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'error', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors


  activate: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    InvoiceTemplate.one 'count_fetched', =>
      InvoiceTemplate.one "refresh", =>
        Permissions.get { person_id: @person_id, can: { invoice: ['create', 'update'] }}, (data) =>
          @new.active { person_id: @person_id, affair_id: @affair_id, can: data }
          @index.active {can: data}
          @edit.active {can: data}
          @edit.hide()

      InvoiceTemplate.fetch()

    InvoiceTemplate.fetch_count()
