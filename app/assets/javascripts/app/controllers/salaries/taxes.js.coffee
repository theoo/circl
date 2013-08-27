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

$.fn.tax = ->
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
    @tax = new SalaryTax()
    @html @view('salaries/taxes/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    form = @tax.fromForm(e.target)

    group = form.exporter_group
    form[group] = true
    delete form['exporter_group']

    @save_with_notifications form, @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

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
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    form = @tax.fromForm(e.target)

    group = form.exporter_group
    form[group] = true
    delete form['exporter_group']

    @save_with_notifications form, @hide

class Index extends App.ExtendedController
  events:
    'tax-show':      'stack_show_window'
    'tax-edit':      'edit'
    'tax-destroy':   'destroy'
    'tax-upload':    'stack_upload_window'

  constructor: (params) ->
    super
    SalaryTax.bind('refresh', @render)

  render: =>
    @html @view('salaries/taxes/index')(@)
    Ui.load_ui(@el)

  stack_show_window: (e) ->
    tax = $(e.target).tax()
    @trigger 'edit', tax.id

  edit: (e) ->
    tax = $(e.target).tax()
    @trigger 'edit', tax.id

  stack_upload_window: (e) ->
    tax = $(e.target).tax()
    e.preventDefault()
    window = Ui.stack_window('upload-salary-taxes', {width: 500, remove_on_close: true})
    controller = new App.UploadSalaryTaxes({el: window; id: tax.id})
    $(window).modal({title: I18n.t('salaries.tax.views.upload_tax')})
    $(window).modal('show')
    controller.activate()

  destroy: (e) ->
    tax = $(e.target).tax()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications tax

class App.SalariesTaxes extends Spine.Controller
  className: 'salaries_taxes'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    SalaryTax.fetch()

    ajax_error = (xhr, statusText, error) =>
      text = I18n.t('common.failed_to_update')
      Ui.notify @el, text, 'error'
      response = JSON.parse(xhr.responseText)
      @renderErrors(response.errors)

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
    Ui.load_ui(@el)

  send: (e) ->
    e.preventDefault()

    Ui.spin_on(@el)

    # jquery.iframe-transport (and this technique) doesn't allows
    # me to trigger error or success event. No matter which status
    # is sent back, the plugin trig the success event.
    on_complete = (xhr, status) =>
      Ui.spin_off(@el)

      response = JSON.parse(xhr.responseText)
      # error
      if Object.keys(response.errors).length > 0
        text = I18n.t('common.failed_to_update')
        Ui.notify @el, text, 'error'
        @renderErrors(response.errors)

      # success
      else
        # if a validation failed, remove it's explanation
        @el.find('.validation_errors_placeholder').css('display', 'none')
        Ui.unlock_submit(@el)
        text = I18n.t('common.successfully_updated')
        Ui.notify @el, text, 'notice'

        # update tax item on tax widget/list
        SalaryTax.fetch(id: tax.tax_id)


    tax = $(e.target).serializeObject()

    settings =
      url: "/salaries/taxes/#{tax.tax_id}/import_data.json"
      type: 'post'
      data: {authenticity_token: @authenticity_token}
      files: @el.find(':file')
      iframe: true
      processData: false

    SalaryTax.ajax().ajax(settings).complete(on_complete)

  activate: ->
    super
    @render()
