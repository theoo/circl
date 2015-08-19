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

Creditor = App.Creditor

$.fn.creditor_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  elementID

CreditorsExtentions =
  constrains: ->
    # Autocompletes buttons
    @creditor_id_field       = @el.find("input[name=creditor_id]")
    @creditor_name_field     = @el.find("input[name=creditor_name]")
    @creditor_button         = @creditor_name_field.parent(".autocompleted").find(".input-group-btn .btn")
    @affair_id_field         = @el.find("input[name=affair_id]")
    @affair_name_field       = @el.find("input[name=affair_name]")
    @affair_help_block       = @el.find(".affairs_count")
    @affair_button           = @affair_name_field.parent(".autocompleted").find(".input-group-btn .btn")

    @vat_field               = @el.find("input[name=vat]")
    @vat_percentage_field    = @el.find("input[name=vat_percentage]")
    @value_field             = @el.find("input[name=value]")
    @custom_value_with_taxes = @el.find("#admin_creditors_custom_value_with_taxes")

    # Required fields
    @required_fields = [ @creditor_id_field,
      @el.find("input[name=value]"),
      @el.find("input[name=invoice_received_on]"),
      @el.find("input[name=invoice_ends_on]"),
      @el.find("input[name=title]") ]

    @update_button       = @el.find('button[type=submit]')

    ### Callbacks ###
    # client is cleared
    @creditor_name_field.on 'keyup search', (e) =>
      if $(e.target).val() == ''
        @disable_creditor()

    # client is selected
    @creditor_name_field.autocomplete('option', 'select', (e, ui) => @enable_creditor(ui.item) )

    # affair is cleared
    @affair_name_field.on 'keyup search', (e) =>
      if $(e.target).val() == ''
        @disable_affair()

    # affair is selected
    @affair_name_field.autocomplete('option', 'select', (e, ui) => @enable_affair(ui.item) )

    # Onload, check if owner or affair are set
    if @creditor_id_field.val() != "" and @creditor_name_field.val() != ""
      @enable_creditor({ id: @creditor_id_field.val() })

    if @affair_id_field.val() != "" and @affair_name_field.val() != ""
      @enable_affair({ id: @affair_id_field.val(), owner_id: @creditor_id_field.val() })

  enable_creditor: (item) ->
    @creditor_id_field.val item.id
    @creditor_button.attr('href', "/people/#{item.id}")
    @creditor_button.attr('disabled', false)

  disable_creditor: ->
    @creditor_id_field.val undefined
    @creditor_button.attr('disabled', true)

  enable_affair: (item) ->
    @affair_id_field.val item.id
    @affair_button.attr('href', "/people/#{item.owner_id}#affairs/#{item.id}")
    @affair_button.attr('disabled', false)

  disable_affair: ->
    @affair_id_field.val undefined
    @affair_button.attr('disabled', true)

  clear_vat: (e) ->
    if $(e.target).is(':checked')
      @vat_field.val("")
      @vat_field.attr(disabled: true)
    else
      @vat_field.attr(disabled: false)
      @update_vat()


class New extends App.ExtendedController

  @include CreditorsExtentions

  events:
    'submit form': 'submit'
    'click a[name="reset"]': 'reset'
    'currency_changed select.currency_selector': 'on_currency_change'
    'click #admin_creditors_custom_value_with_taxes': 'clear_vat'

  constructor: (params) ->
    super
    @setup_vat
      ids_prefix: 'admin_creditors_'
      bind_events: (App.ApplicationSetting.value('use_vat') == "true")

  render: =>
    @creditor = new Creditor(vat_percentage: App.ApplicationSetting.value('service_vat_rate'))
    @html @view('admin/creditors/form')(@)
    @constrains()

    # Click it so the callback is called
    @custom_value_with_taxes.click()

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @creditor.fromForm(e.target), @render


class Edit extends App.ExtendedController

  @include CreditorsExtentions

  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name="creditor_destroy"]': 'destroy'
    'currency_changed select.currency_selector': 'on_currency_change'
    'click #admin_creditors_custom_value_with_taxes': 'clear_vat'

  constructor: ->
    super
    @setup_vat
      ids_prefix: 'admin_creditors_'
      bind_events: (App.ApplicationSetting.value('use_vat') == "true")

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless Creditor.exists(@id)
    @creditor = Creditor.find(@id)
    @html @view('admin/creditors/form')(@)
    @constrains()
    @show()

  submit: (e) ->
    e.preventDefault()
    # re-render so value is updated when custom_value_with_taxes is checked
    @save_with_notifications @creditor.fromForm(e.target), @render

  destroy: (e) ->
    e.preventDefault()
    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      @destroy_with_notifications @creditor, =>
        @hide()


class Index extends App.ExtendedController
  events:
    'click tbody tr.item td:not(.ignore-click)':      'edit'
    'click button[name=admin-creditors-export]':      'export'
    'click button[name="admin-creditors-documents"]': 'documents'
    'datatable_redraw':                               'table_redraw'
    'click button[name=creditors-group-edit]':        'group_edit'
    'change thead input[name="select_all"]':                'toggle_checks'
    'change tbody input[type="checkbox"]':                  'toggle_check'

  constructor: (params) ->
    super
    Creditor.bind 'refresh', @render
    @selected_ids = []

  render: =>
    @html @view('admin/creditors/index')(@)

  table_redraw: =>
    # Unbind checkbox in header (so it doesn't try to sort)
    @el.find('thead>tr>th.ignore-sort').each (index, el) ->
      $(el).unbind 'click'

    # Add class and checkbox to each item
    @el.find('tbody>tr.item>td:last-child').each (index, el) ->
      $(el).addClass('number ignore-click')
      $(el).html "<input type='checkbox'>"

    # Rechecked selected items
    $(@selected_ids).each (index, item) =>
      @el.find("tr[data-id=#{item}] input[type='checkbox']").attr(checked: true)

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')

    # Prevent default behavior (do not reload table)
    Creditor.unbind 'refresh'
    Creditor.one 'refresh', =>
      @trigger 'edit', id
      # Rebind refresh
      Creditor.bind 'refresh', @render
    Creditor.fetch(id: id)

  export: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='admin-invoices-export-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Modal alternative
    win.find('.modal-body').remove()
    win.find('.modal-footer').remove()

    controller = new App.ExportCreditors({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

  documents: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='admin-creditors-documents-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new CreditorsDocumentsMachine({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

  toggle_check: (e) ->
    id = $(e.target).creditor_id()
    if $(e.target).is(":checked")
      @selected_ids.push id
    else
      index = @selected_ids.indexOf(id)
      @selected_ids.splice index, 1

  toggle_checks: (e) ->
    # status = $(e.target).is(":checked")

    # table = $(e.target).closest("table")
    # datatable = table.dataTable()
    # ids = $(datatable.fnGetNodes()).map (index, c) -> $(c).product_id()

  group_edit: (e) ->

  toggle_group_edit_button: ->
    # btn = @el.find("button[name=affair-product-items-group-edit]")
    # if @selected?.length > 0
    #   btn.attr(disabled: false)
    # else
    #   btn.attr(disabled: true)


class App.ExportCreditors extends App.ExtendedController
  events:
    'submit form': 'validate'

  constructor: (params) ->
    super
    @account = App.ApplicationSetting.value("creditors_debit_account")
    @counterpart_account = App.ApplicationSetting.value("creditors_credit_account")
    @statuses = gon.creditor_statuses
    @date_fields = gon.creditor_date_fields

  # FIXME validation should be in model
  validate: (e) ->
    errors = new App.ErrorsList

    # Clear errors
    @reset_notifications()

    form = $(e.target)
    from = form.find('input[name=from]').val()
    to = form.find('input[name=to]').val()

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

    if from.length > 0 and to.length > 0
      if ! @validate_interval(from, to)
        errors.add ['from', I18n.t('common.errors.from_should_be_before_to')].to_property()

    if errors.is_empty()
      @render_success()
    else
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('admin/creditors/export')(@)

  activate: ->
    super
    @render()


# class CreditorsDocumentsMachine extends App.ExtendedController
#   events:
#     'submit form': 'validate'
#     'change #admin_creditors_document_export_format': 'format_changed'

#   constructor: (params) ->
#     super
#     @content = params.content

#   activate: (params)->
#     @format = 'csv' # default format
#     @form_url = App.Creditor.url()

#     @template_class = 'Creditor'
#     App.Creditor.one 'statuses_fetched', =>
#       @render()
#     App.Creditor.fetch_statuses()

#   render: =>
#     @html @view('admin/creditors/documents')(@)

#     @el.find("#admin_creditors_document_export_threshold_value_global").attr(disabled: true)
#     @el.find("#admin_creditors_document_export_threshold_overpaid_global").attr(disabled: true)

#   validate: (e) ->
#     errors = new App.ErrorsList

#     if @el.find("#admin_creditors_document_export_format").val() != 'csv'
#       unless @el.find("#admin_creditors_document_export_template").val()
#         errors.add ['generic_template_id', I18n.t("activerecord.errors.messages.blank")].to_property()

#     if errors.is_empty()
#       # @render_success() # do nothing...
#     else
#       e.preventDefault()
#       @render_errors(errors.errors)

#   format_changed: (e) ->
#     @format = $(e.target).val()
#     @el.find("form").attr('action', @form_url + "." + @format)


class App.AdminCreditors extends Spine.Controller
  className: 'creditors'

  constructor: (params) ->
    super

    @index = new Index
    @new = new New
    @edit = new Edit
    @append(@new, @edit, @index)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()
    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

    @index.bind 'edit', (id) =>
      @edit.active(id: id)
      @index.active(id: id)

  activate: ->
    super
    @new.render()
    @index.render()
