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

$.fn.creditor = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Creditor.find(elementID)

FormFieldsController =
  bind_provider_and_affair: ->
    @creditor_name_field = @el.find("input[name=creditor_name]")
    @creditor_id_field   = @el.find("input[name=creditor_id]")
    @creditor_button     = @creditor_name_field.parent(".autocompleted").find(".input-group-btn .btn")
    @affair_name_field   = @el.find("input[name=affair_name]")
    @affair_id_field     = @el.find("input[name=affair_id]")
    @affair_help_block   = @el.find(".affairs_count")
    @affair_button       = @affair_name_field.parent(".autocompleted").find(".input-group-btn .btn")

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
    @set_affairs_search_url(item.id)
    @affair_help_block.html I18n.t("task.views.affairs_found", count: item.affairs_count)
    @affair_help_block.effect('highlight')

    @creditor_button.attr('href', "/people/#{item.id}")
    @creditor_button.attr('disabled', false)

  disable_creditor: ->
    @reset_affairs_search_url()
    @disable_submit()
    @creditor_button.attr('disabled', true)
    @affair_button.attr('disabled', true)

  enable_affair: (item) ->
    @creditor_id_field.val item.owner_id
    @creditor_name_field.val item.owner_name
    @creditor_button.attr('href', "/people/#{item.owner_id}")
    @creditor_button.attr('disabled', false)

    @affair_id_field.val item.id
    @enable_submit()

    @affair_button.attr('href', "/people/#{item.owner_id}#affairs/#{item.id}")
    @affair_button.attr('disabled', false)

  disable_affair: ->
    @disable_submit()
    @affair_button.attr('disabled', true)

  set_affairs_search_url: (id) ->
    @affair_name_field.autocomplete({source: '/people/' + id + '/affairs/search'})

  reset_affairs_search_url: ->
    @affair_name_field.val("")
    @affair_name_field.autocomplete({source: '/admin/affairs/search'})

  disable_submit: ->
    @update_button.addClass('disabled')

  enable_submit: ->
    @update_button.removeClass('disabled')


class New extends App.ExtendedController

  @include FormFieldsController

  events:
    'submit form': 'submit'
    'click a[name="reset"]': 'reset'

  constructor: (params) ->
    super

  render: =>
    @creditor = new Creditor

    @html @view('admin/creditors/form')(@)
    @bind_provider_and_affair()

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @creditor.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @creditor = Creditor.find(@id)
    @render()

  render: =>
    return unless Creditor.exists(@id)
    @html @view('admin/creditors/form')(@)
    @bind_provider_and_affair()
    @show()

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @creditor.fromForm(e.target)

  destroy: (e) ->
    e.preventDefault()
    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      @destroy_with_notifications @creditor, =>
        @hide()

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'click button[name="admin-creditors-documents"]':  'documents'

  constructor: (params) ->
    super
    Creditor.bind 'refresh', @render

  render: =>
    @html @view('admin/creditors/index')(@)

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')

    # Prevent default behavior (do not reload table)
    Creditor.unbind 'refresh'
    Creditor.one 'refresh', =>
      @trigger 'edit', id
    Creditor.fetch(id: id)

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

class CreditorsDocumentsMachine extends App.ExtendedController
  events:
    'submit form': 'validate'
    'change #admin_creditors_document_export_format': 'format_changed'

  constructor: (params) ->
    super
    @content = params.content

  activate: (params)->
    @format = 'csv' # default format
    @form_url = App.Creditor.url()

    @template_class = 'Creditor'
    App.Creditor.one 'statuses_fetched', =>
      @render()
    App.Creditor.fetch_statuses()

  render: =>
    @html @view('admin/creditors/documents')(@)

    @el.find("#admin_creditors_document_export_threshold_value_global").attr(disabled: true)
    @el.find("#admin_creditors_document_export_threshold_overpaid_global").attr(disabled: true)

  validate: (e) ->
    errors = new App.ErrorsList

    if @el.find("#admin_creditors_document_export_format").val() != 'csv'
      unless @el.find("#admin_creditors_document_export_template").val()
        errors.add ['generic_template_id', I18n.t("activerecord.errors.messages.blank")].to_property()

    if errors.is_empty()
      # @render_success() # do nothing...
    else
      e.preventDefault()
      @render_errors(errors.errors)

  format_changed: (e) ->
    @format = $(e.target).val()
    @el.find("form").attr('action', @form_url + "." + @format)

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
