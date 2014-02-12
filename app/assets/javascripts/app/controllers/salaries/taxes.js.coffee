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

SalaryTax = App.SalaryTax

$.fn.salaries_tax = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  SalaryTax.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super
    @all_models = []

  set_models: (models) =>
    @all_models = models
    @render()

  render: =>
    @tax = new SalaryTax(archive: false)
    @html @view('salaries/taxes/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @tax.load(data)

    group = @tax.exporter_group
    @tax[group] = true
    delete @tax['exporter_group']
    @tax.archive = data.archive?

    @save_with_notifications @tax, @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name=tax-upload]':  'stack_upload_window'
    'click button[name=tax-destroy]': 'destroy'

  constructor: ->
    super
    @all_models = []

  active: (params) ->
    @id = params.id if params.id
    @render()

  set_models: (models) =>
    @all_models = models
    @render()

  render: =>
    return unless SalaryTax.exists(@id)
    @show()
    @tax = SalaryTax.find(@id)
    @html @view('salaries/taxes/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @tax.load(data)

    group = @tax.exporter_group
    @tax[group] = true
    delete @tax['exporter_group']
    @tax.archive = data.archive?

    @save_with_notifications @tax, @hide

  stack_upload_window: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salaries-taxes-upload-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new App.UploadSalaryTaxes({el: win.find('.modal-content'); id: @tax.id})

    controller.activate()
    win.modal('show')

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @tax, =>
        @hide()

class Index extends App.ExtendedController
  events:
    'click tr':      'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    SalaryTax.bind('refresh', @render)

  render: =>
    @html @view('salaries/taxes/index')(@)

  edit: (e) ->
    tax = $(e.target).salaries_tax()
    @activate_in_list(e.target)
    @trigger 'edit', tax.id

  table_redraw: =>
    if @tag
      target = $(@el).find("tr[data-id=#{@tag.id}]")

    @activate_in_list(target)

class App.SalariesTaxes extends Spine.Controller
  className: 'salaries_taxes'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @new.bind 'edit', (id) =>
      @edit.active(id: id)
    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    SalaryTax.fetch()

    ajax_error = (xhr, statusText, error) =>
      text = I18n.t('common.errors.failed_to_update')
      response = JSON.parse(xhr.responseText)
      @render_errors(response.errors)

    ajax_success = (data, textStatus, jqXHR) =>
      @new.set_models(data.models)
      @edit.set_models(data.models)

    settings =
      url: "#{SalaryTax.url()}/models"
      type: 'GET'
    SalaryTax.ajax().ajax(settings).error(ajax_error).success(ajax_success)

    @new.render()

class App.UploadSalaryTaxes extends App.ExtendedController
  events:
    'submit form': 'send'

  constructor: (params) ->
    super

    @tax = SalaryTax.find(params.id)

  render: ->
    @html @view('salaries/taxes/upload')(@)

  send: (e) ->
    e.preventDefault()

    # jquery.iframe-transport (and this technique) doesn't allows
    # me to trigger error or success event. No matter which status
    # is sent back, the plugin trig the success event.
    on_complete = (xhr, status) =>

      response = JSON.parse(xhr.responseText)
      # error
      if Object.keys(response.errors).length > 0
        @render_errors(response.errors)

      # success
      else
        # if a validation failed, remove it's explanation
        @el.find('.validation_errors_placeholder').css('display', 'none')

        # update tax item on tax widget/list
        SalaryTax.fetch(id: tax.tax_id)
        @el.closest(".modal").modal('hide')

    tax = $(e.target).serializeObject()

    settings =
      url: "/salaries/taxes/#{tax.tax_id}/import_data.json"
      type: 'post'
      data: {authenticity_token: App.authenticity_token()}
      files: @el.find(':file')
      iframe: true
      processData: false

    SalaryTax.ajax().ajax(settings).complete(on_complete)

  activate: ->
    super
    @render()
