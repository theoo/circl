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

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="reset"]': 'reset'

  constructor: (params) ->
    super

  render: =>
    @creditor = new Creditor

    @html @view('admin/creditors/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @creditor.fromForm(e.target), @render

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
    window.location = "/admin/creditors/#{id}"

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
    @append(@new, @index)

  activate: ->
    super
    @new.render()
    @index.render()
