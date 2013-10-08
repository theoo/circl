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

Invoice = App.Invoice

$.fn.invoice = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Invoice.find(elementID)

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'click button[name=admin-invoices-export]':  'stack_export_window'

  constructor: (params) ->
    super
    Invoice.bind('refresh', @render)

  render: =>
    @html @view('admin/invoices/index')(@)

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).closest("tr.item").attr('data-id')

    # Do not refresh index, the default behavior
    Invoice.unbind 'refresh'

    Invoice.one 'refresh', =>
      invoice = Invoice.find(id)
      window.location = "/people/#{invoice.buyer_id}?folding=person_affairs"
    Invoice.fetch(id: id)

  stack_export_window: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='admin-invoices-export-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Modal alternative
    win.find('.modal-body').remove()
    win.find('.modal-footer').remove()

    controller = new App.ExportInvoices({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

class App.ExportInvoices extends App.ExtendedController
  events:
    'submit form': 'validate'
    # 'click input[name=admin-invoices-export]': 'validate'

  constructor: (params) ->
    super
    @account = App.ApplicationSetting.value("invoices_debit_account")
    @counterpart_account = App.ApplicationSetting.value("invoices_credit_account")

  # FIXME validation should be in model
  validate: (e) ->
    errors = new App.ErrorsList

    # Clear errors
    @reset_notifications()

    form = $(e.target)
    from = form.find('input[name=from]').val()
    to = form.find('input[name=to]').val()
    account = form.find('input[name=account]').val()
    counterpart = form.find('input[name=counterpart_account]').val()

    if from.length == 0
      errors.add ['from', I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add ['to', I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add ['to', I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add ['to', I18n.t('common.errors.date_must_match_format')].to_property()

    if account.length == 0
      errors.add ['account', I18n.t("activerecord.errors.messages.blank")].to_property()

    if counterpart.length == 0
      errors.add ['counterpart_account', I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('admin/invoices/export')(@)

  activate: ->
    super
    @render()

class App.AdminInvoices extends Spine.Controller
  className: 'adminInvoices'

  constructor: (params) ->
    super

    @index = new Index
    @append(@index)

  activate: ->
    super
    Invoice.fetch()
