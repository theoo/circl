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

$.fn.salary_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class Index extends App.ExtendedController
  events:
    'click tr.item td:not(.ignore-click)'              : 'edit'
    'click a[name=salary-check-as-paid]'               : 'check_as_paid'
    'click a[name=salary-copy]'                        : 'copy_reference'
    'click a[name=salary-download]'                    : 'download'
    'click a[name=salary-destroy]'                     : 'destroy'
    'click a[name=salaries-export]'                    : 'stack_export_generic'
    'click a[name=salaries-export-to-accounting]'      : 'stack_export_to_accounting_window'
    'click a[name=salaries-export-to-ocas]'            : 'stack_export_to_ocas_window'
    'click a[name=salaries-export-to-eLohnausweisSSK]' : 'stack_export_to_eLohnausweisSSK_window'

  constructor: (params) ->
    Salary.bind('refresh', @render)
    super

  render: =>
    @html @view('salaries/salaries/index')(@)

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).salary_id()
    Salary.one 'refresh', =>
      salary = Salary.find(id)
      window.location = "/people/#{salary.person_id}#salaries"
    Salary.fetch(id: id)

  destroy: (e) ->
    e.preventDefault()
    id = $(e.target).salary_id()

    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      Salary.one 'refresh', =>
        salary = Salary.find(id)
        @destroy_with_notifications(salary)
        Salary.fetch()
      Salary.fetch(id: id)

  check_as_paid: (e) ->
    e.preventDefault()
    id = $(e.target).salary_id()
    @confirm I18n.t('common.are_you_sure'), 'info', =>
      Salary.one 'refresh', =>
        salary = Salary.find(id)
        salary.updateAttributes(paid: true)
        Salary.refresh([], clear: true)
        Salary.fetch()
      Salary.fetch(id: id)

  copy_reference: (e) ->
    e.preventDefault()
    id = $(e.target).salary_id()

    Salary.one 'refresh', =>
      salary = Salary.find(id)
      query       = new App.QueryPreset
      url         = "#{Salary.url()}/#{salary.id}/copy_reference"
      title       = I18n.t('salary.views.copy_reference_title') + " <i>" + salary.title + "</i>"
      message     = I18n.t('salary.views.copy_reference_message')

      Directory.search_with_custom_action query,
        url: url
        title: title
        message: message

    Salary.fetch(id: id)

  download: (e) ->
    e.preventDefault()
    id = $(e.target).salary_id()
    Salary.one 'refresh', =>
      salary = Salary.find(id)
      window.location = "/people/#{salary.person_id}/salaries/#{salary.id}.pdf"
    Salary.fetch(id: id)

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

    if from.length > 0 and to.length > 0
      if ! @validate_interval(from, to)
        errors.add ['from', I18n.t('common.errors.from_should_be_before_to')].to_property()

    if errors.is_empty()
      @render_success()
    else
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

    if from.length > 0 and to.length > 0
      if ! @validate_interval(from, to)
        errors.add ['from', I18n.t('common.errors.from_should_be_before_to')].to_property()

    if errors.is_empty()
      @render_success()
    else
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
    year = form.find('#export_ocas_year').val()

    if year.length == 0
      errors.add ['year', I18n.t("activerecord.errors.messages.blank")].to_property()

    if errors.is_empty()
      @render_success()
    else
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_ocas')(@)

  fetch_years: ->
    ajax_error = (xhr, statusText, error) =>
      text = I18n.t('common.errors.failed_to_retrieve_data')
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
    year = form.find('#export_certificates_year').val()

    if year.length == 0
      errors.add ['year', I18n.t("activerecord.errors.messages.blank")].to_property()

    if errors.is_empty()
      @render_success()
    else
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_elohnausweisssk')(@)

  fetch_years: ->
    ajax_error = (xhr, statusText, error) =>
      text = I18n.t('common.errors.failed_to_retrieve_data')
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
