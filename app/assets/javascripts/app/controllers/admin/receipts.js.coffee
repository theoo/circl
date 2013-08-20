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
Receipt = App.Receipt
InvoiceTemplate = App.InvoiceTemplate

$.fn.receipt = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Receipt.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    InvoiceTemplate.bind('refresh', @render)

  render: =>
    @receipt = new Receipt(value: 0)
    @receipt.means_of_payment = 'CCP'

    @html @view('admin/receipts/form')(@)
    Ui.load_ui(@el)

    owner_name_field = @el.find 'input[name="owner_name"]'
    owner_id_field = @el.find 'input[name="owner_id"]'

    affair_title_field = @el.find 'input[name="affair_title"]'
    affair_id_field = @el.find('input[name="affair_id"]')

    invoice_title_field = @el.find 'input[name="invoice_title"]'
    invoice_id_field = @el.find('input[name="invoice_id"]')

    subscription_title_field = @el.find 'input[name="subscription_title"]'
    subscription_id_field = @el.find 'input[name="subscription_id"]'

    # enable affair field if a person is selected
    # AND re-enable subscription if disabled before
    owner_name_field.autocomplete('option', 'select', (e, ui) =>
      owner_id = ui.item.id
      owner_id_field.attr('value', owner_id)

      # enable affair
      affair_title_field.autocomplete({source: '/people/' + owner_id + '/affairs/search'})
      affair_title_field.removeAttr('disabled')

      # re-enable subscription
      subscription_title_field.removeAttr('disabled')
    )
    # re-disable affair/invoice if person field is cleared
    owner_name_field.on 'keyup search', (e) =>
      if $(e.target).attr('value') == ''
        # disable invoice
        affair_title_field.attr('value', '')
        affair_id_field.attr('value', null)
        affair_title_field.attr('disabled', 'disabled')

        # disable invoice
        invoice_title_field.attr('value', '')
        invoice_id_field.attr('value', null)
        invoice_title_field.attr('disabled', 'disabled')

    # disable subscription field if an affair is selected
    # AND enable invoice field if an affair is selected
    affair_title_field.autocomplete('option', 'select', (e, ui) =>
      affair_id = ui.item.id
      owner_id = owner_id_field.val()
      affair_id_field.attr('value', affair_id)

      # disable subscription
      subscription_title_field.attr('value', '')
      subscription_id_field.attr('value', null)
      subscription_title_field.attr('disabled', 'disabled')

      # enable invoice
      invoice_title_field.autocomplete({source: '/people/' + owner_id + '/affairs/' + affair_id + '/invoices/search'})
      invoice_title_field.removeAttr('disabled')
    )
    # re-enable subscription if affair's field is cleared
    # AND disable invoice
    affair_title_field.on 'keyup search', (e) =>
      if $(e.target).attr('value') == ''
        # enable subscription
        subscription_title_field.removeAttr('disabled')

        # disable invoice
        invoice_title_field.attr('value', '')
        invoice_id_field.attr('value', null)
        invoice_title_field.attr('disabled', 'disabled')

    # disable affair/invoice if a subscription is selected
    subscription_title_field.autocomplete('option', 'select', (e, ui) =>
      subscription_id = ui.item.id
      subscription_id_field.attr('value', subscription_id)

      # disable affair
      affair_title_field.attr('value', '')
      affair_id_field.attr('value', null)
      affair_title_field.attr('disabled', 'disabled')

      # disable invoice
      invoice_title_field.attr('value', '')
      invoice_id_field.attr('value', null)
      invoice_title_field.attr('disabled', 'disabled')
    )
    # re-enable affair if subscription is cleared
    subscription_title_field.on 'keyup search', (e) =>
      if $(e.target).attr('value') == ''
        affair_title_field.removeAttr('disabled')

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @receipt.fromForm(e.target), @render

class Index extends App.ExtendedController
  events:
    'receipt-edit': 'edit'
    'click input[name="receipts_export"]':  'stack_export_window'
    'click input[name="receipts_import"]':  'stack_import_window'

  constructor: (params) ->
    super
    Receipt.bind('refresh', @render)

  render: =>
    @html @view('admin/receipts/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    id = $(e.target).attr('data-id')
    Receipt.one 'refresh', =>
      receipt = Receipt.find(id)
      window.location = "/people/#{receipt.owner_id}?folding=person_affairs"
    Receipt.fetch(id: id)

  stack_export_window: (e) ->
    e.preventDefault()
    window = Ui.stack_window('export-receipts', {width: 400, remove_on_close: true})
    controller = new App.ExportReceipts({el: window})
    $(window).dialog({title: I18n.t('receipt.views.export')})
    $(window).dialog('open')
    controller.activate()

  stack_import_window: (e) ->
    e.preventDefault()
    window = Ui.stack_window('import-receipts', {width: 800, remove_on_close: true})
    controller = new App.ImportReceipts({el: window})
    $(window).dialog({title: I18n.t('receipt.views.import_bank_file')})
    $(window).dialog('open')
    controller.activate()

class App.ExportReceipts extends App.ExtendedController
  events:
    'submit form': 'validate'

  constructor: (params) ->
    super
    @account = App.ApplicationSetting.value("receipts_debit_account")
    @counterpart_account = App.ApplicationSetting.value("receipts_credit_account")

  validate: (e) ->
    errors = new App.ErrorsList

    form = $(e.target)
    from = form.find('input[name=from]').val()
    to = form.find('input[name=to]').val()
    account = form.find('input[name=account]').val()
    counterpart = form.find('input[name=counterpart_account]').val()

    if from.length == 0
      errors.add [I18n.t("common.from"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add [I18n.t("common.from"), I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add [I18n.t("common.to"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add [I18n.t("common.to"), I18n.t('common.errors.date_must_match_format')].to_property()

    if account.length == 0
      errors.add [I18n.t("receipt.views.account"), I18n.t("activerecord.errors.messages.blank")].to_property()

    if counterpart.length == 0
      errors.add [I18n.t("receipt.views.counterpart_account"), I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @renderErrors(errors.errors)

  render: ->
    @html @view('admin/receipts/export')(@)
    Ui.load_ui(@el)

  activate: ->
    super
    @render()

class App.AdminReceipts extends Spine.Controller
  className: 'adminReceipts'

  constructor: (params) ->
    super

    @index = new Index
    @new = new New
    @append(@new, @index)

  activate: ->
    super
    InvoiceTemplate.fetch()
    @index.render()
