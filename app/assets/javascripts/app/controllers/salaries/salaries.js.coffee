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

Salary = App.Salary

$.fn.salary = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Salary.find(elementID)

class Index extends App.ExtendedController
  events:
    'click tr.item td:not(.ignore-click)'                   : 'edit'
    'click button[name=salary-check-as-paid]'      : 'check_as_paid'
    'click button[name=salary-copy]'               : 'copy_reference'
    'click button[name=salary-destroy]'            : 'destroy'
    'click button[name=salaries-export]'                    : 'stack_export_generic'
    'click button[name=salaries-export-to-accounting]'      : 'stack_export_to_accounting_window'
    'click button[name=salaries-export-to-ocas]'            : 'stack_export_to_ocas_window'
    'click button[name=salaries-export-to-eLohnausweisSSK]' : 'stack_export_to_eLohnausweisSSK_window'

  constructor: (params) ->
    Salary.bind('refresh', @render)
    super

  render: =>
    @html @view('salaries/salaries/index')(@)

  edit: (e) ->
    e.preventDefault()
    salary = $(e.target).salary()
    window.location = "/people/#{salary.person_id}#salaries"

  destroy: (e) ->
    e.preventDefault()
    salary = $(e.target).salary()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications(salary)

  check_as_paid: (e) ->
    e.preventDefault()
    salary = $(e.target).salary()
    if confirm(I18n.t('common.are_you_sure'))
      salary.updateAttributes(paid: true)
      Salary.refresh([], clear: true)
      Salary.fetch()

  copy_reference: (e) ->
    e.preventDefault()
    salary = $(e.target).salary()

    query       = new App.QueryPreset
    url         = "#{Salary.url()}/#{salary.id}/copy_reference"
    title       = I18n.t('salary.views.copy_reference_title') + " <i>" + salary.title + "</i>"
    message     = I18n.t('salary.views.copy_reference_message')

    Directory.search_with_custom_action query,
      url: url
      title: title
      message: message

  stack_export_generic: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salaries-export-generic-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new App.ExportSalaries({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

  stack_export_to_accounting_window: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salaries-export-to-accounting-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new App.ExportToAccountingSalaries({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

  stack_export_to_ocas_window: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salaries-export-to-ocas-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new App.ExportToOcasSalaries({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

  stack_export_to_eLohnausweisSSK_window: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salaries-export-to-elohnausweisssk-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new App.ExportToELohnausweisSSKSalaries({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

class App.ExportSalaries extends App.ExtendedController
  events:
    'submit form': 'validate'

  constructor: (params) ->
    super

    now = new Date
    year = now.getFullYear()
    @export = { from: "01-01-" + year , to: "31-12-" + year}

  validate: (e) ->
    errors = new App.ErrorsList

    form = $(e.target)
    from = form.find('input[name=from]').val()
    to = form.find('input[name=to]').val()

    if from.length == 0
      errors.add ['from', I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add ['from', I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add ['to', I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add ['to', I18n.t('common.errors.date_must_match_format')].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export')(@)

  activate: ->
    super
    @render()


class App.ExportToAccountingSalaries extends App.ExtendedController
  events:
    'submit form': 'validate'

  constructor: (params) ->
    super

    now = new Date
    year = now.getFullYear()
    @export = { from: "01-01-" + year , to: "31-12-" + year}

  validate: (e) ->
    errors = new App.ErrorsList

    form = $(e.target)
    from = form.find('input[name=from]').val()
    to = form.find('input[name=to]').val()

    if from.length == 0
      errors.add ['from', I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add ['from', I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add ['to', I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add ['to', I18n.t('common.errors.date_must_match_format')].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_accounting')(@)

  activate: ->
    super
    @render()

class App.ExportToOcasSalaries extends App.ExtendedController
  events:
    'submit form': 'validate'

  constructor: (params) ->
    super

  validate: (e) ->
    errors = new App.ErrorsList

    form = $(e.target)
    year = form.find('#salaries_export_ocas_year').val()

    if year.length == 0
      errors.add ['year', I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_ocas')(@)

  fetch_years: ->
    ajax_error = (xhr, statusText, error) =>
      text = I18n.t('common.failed_to_retrive_data')
      Ui.notify @el, text, 'error'

    ajax_success = (data, textStatus, jqXHR) =>
      @from = data.from
      @to   = data.to
      @render()

    settings =
      url: "#{Salary.url()}/available_years"
      type: 'GET'

    Salary.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  activate: ->
    super
    @fetch_years()

class App.ExportToELohnausweisSSKSalaries extends App.ExtendedController
  events:
    'submit form': 'validate'

  constructor: (params) ->
    super

  validate: (e) ->
    errors = new App.ErrorsList

    form = $(e.target)
    year = form.find('#salaries_export_certificates_year').val()

    if year.length == 0
      errors.add ['year', I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_elohnausweisssk')(@)

  fetch_years: ->
    ajax_error = (xhr, statusText, error) =>
      text = I18n.t('common.failed_to_retrive_data')
      Ui.notify @el, text, 'error'

    ajax_success = (data, textStatus, jqXHR) =>
      @from = data.from
      @to   = data.to
      @render()

    settings =
      url: "#{Salary.url()}/available_years"
      type: 'GET'

    Salary.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  activate: ->
    super
    @fetch_years()

class App.Salaries extends Spine.Controller
  className: 'salariesSalaries'

  constructor: (params) ->
    super

    @index = new Index(person_id: @person_id)

    # Render errors on index
    @index.bind 'destroyError', (id, errors) =>
      @index.render_errors errors

    @append(@index)

  activate: ->
    super
    Salary.fetch()
