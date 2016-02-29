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
AffairsCondition = App.AffairsCondition

$.fn.invoice = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonAffairInvoice.find(elementID)

# Modules
ConditionsController =
  update_conditions: (e) ->
    e.preventDefault()
    id = $(e.target).val()
    textarea = @el.find('#person_affair_invoice_conditions')

    if AffairsCondition.exists(id)
      condition = AffairsCondition.find(id)
      textarea.val(condition.description)
    else
      textarea.val("")

ValueWithTaxesController =
  clear_vat: (e) ->
    if $(e.target).is(':checked')
      @el.find("#person_affair_invoice_vat").val("")

class New extends App.ExtendedController

  @include ConditionsController
  @include ValueWithTaxesController

  events:
    'submit form': 'submit'
    'currency_changed select.currency_selector': 'on_currency_change'
    'change select[name="condition_id"]': 'update_conditions'
    'click a[name="reset"]': 'reset'
    'click #person_affair_invoice_custom_value_with_taxes': 'clear_vat'

  constructor: (params) ->
    super

    @setup_vat
      ids_prefix: 'person_affair_invoice_'
      bind_events: App.ApplicationSetting.value('use_vat')

    PersonAffair.bind('refresh', @active)
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
      @invoice = new PersonAffairInvoice(value: 0, cancelled: false, offered: false)
      @invoice.printed_address = @affair.buyer_address
      @invoice.title = @affair.title
      @invoice.description = @affair.description
      @invoice.created_at = (new Date).to_view()
      # re-calculate invoices_value instead of using information from rails
      invoices_value = PersonAffairInvoice.billable().reduce(((sum, i) -> sum + i.value), 0)
      @invoice.value = (@affair.value - invoices_value).toFixed(2)
      @invoice.vat_percentage = @affair.vat_percentage
    else
      @invoice = new PersonAffairInvoice(value: 0)

    if @affair_id and PersonAffair.exists(@affair_id)
      @affair = PersonAffair.find(@affair_id)
      @invoice.conditions = @affair.conditions
    else
      # FIXME Does it really makes sense ? Perhaps it's better to remove this setting
      @invoice.conditions = App.ApplicationSetting.value("default_invoice_conditions")

    @html @view('people/affairs/invoices/form')(@)
    @adjust_vat()

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairInvoice.url() == undefined

  submit: (e) ->
    e.preventDefault()

    data = $(e.target).serializeObject()
    @invoice.load(data)
    @invoice.cancelled = data.cancelled?
    @invoice.offered = data.offered?
    @invoice.custom_value_with_taxes = data.custom_value_with_taxes?
    @save_with_notifications @invoice, (id) =>
      PersonAffair.fetch(id: @affair_id)
      @trigger('edit', id)

class Edit extends App.ExtendedController

  @include ConditionsController
  @include ValueWithTaxesController

  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click a[name="affair_invoice_pdf"]': 'pdf'
    'click a[name="invoice-destroy"]': 'destroy'
    'click a[name="invoice-add-receipt"]': 'add_receipt'
    'change select[name="condition_id"]': 'update_conditions'
    'currency_changed select.currency_selector': 'on_currency_change'
    'click #person_affair_invoice_custom_value_with_taxes': 'clear_vat'

  constructor: (params) ->
    super

    @setup_vat
      ids_prefix: 'person_affair_invoice_'
      bind_events: App.ApplicationSetting.value('use_vat')

  active: (params) ->
    @can = params.can if params.can
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonAffairInvoice.exists(@id) && @can
    @show()

    @invoice = PersonAffairInvoice.find(@id)
    @affair = PersonAffair.find(@invoice.affair_id)
    @html @view('people/affairs/invoices/form')(@)

    if App.ApplicationSetting.value('use_vat')
      @highlight_vat()

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @invoice.load(data)
    @invoice.cancelled = data.cancelled?
    @invoice.offered = data.offered?
    @invoice.custom_value_with_taxes = data.custom_value_with_taxes?
    @save_with_notifications @invoice, =>
      PersonAffair.fetch(id: @affair.id)
      PersonAffairReceipt.fetch()
      @render()

  destroy: (e) ->
    e.preventDefault()
    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      @destroy_with_notifications @invoice, =>
        PersonAffair.fetch(id: @affair.id)
        PersonAffairReceipt.fetch()
        @hide()

  pdf: (e) ->
    e.preventDefault()
    window.location = "#{PersonAffairInvoice.url()}/#{@invoice.id}.pdf"

  add_receipt: (e) ->
    e.preventDefault()
    person_affair_receipts_ctrl = $("#person_affair_receipts").data('controller')
    person_affair_receipts_ctrl.index.trigger 'new',
      person_id: @person_id,
      affair_id: @invoice.affair_id,
      invoice: @invoice

class Index extends App.ExtendedController
  events:
    'click tr.item':    'edit'
    'datatable_redraw': 'table_redraw'
    'mouseover tr.item':'item_over'
    'mouseout tr.item': 'item_out'
    'click a[name=affair_invoices_csv]': 'csv'
    'click a[name=affair_invoices_pdf]': 'pdf'
    'click a[name=affair_invoices_odt]': 'odt'

  constructor: (params) ->
    super
    PersonAffairInvoice.bind('refresh', @render)
    InvoiceTemplate.bind('refresh', @render)

  active: (params) ->
    @can = params.can if params.can
    if params
      @person_id = params.person_id
      @invoice = PersonAffairInvoice.find(params.invoice_id) if params.invoice_id
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

  csv: (e) ->
    e.preventDefault()
    window.location = PersonAffairInvoice.url() + ".csv"

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_invoices_template").val()
    window.location = PersonAffairInvoice.url() + ".pdf?template_id=#{@template_id}"

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_invoices_template").val()
    window.location = PersonAffairInvoice.url() + ".odt?template_id=#{@template_id}"


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

    @new.bind 'edit', (id) =>
      @edit.active(id: id, person_id: @person_id)
      @index.active(invoice_id: id, person_id: @person_id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', =>
      @new.show()
      @new.render()

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
