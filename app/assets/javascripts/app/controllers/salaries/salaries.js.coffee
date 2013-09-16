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
    'salary-edit'    : 'edit'
    'salary-paid'    : 'check_as_paid'
    'salary-copy'    : 'copy_reference'
    'salary-destroy' : 'destroy'
    'click #export'                    : 'stack_export_window'
    'click #export_to_accounting'      : 'stack_export_to_accounting_window'
    'click #export_to_ocas'            : 'stack_export_to_ocas_window'
    'click #export_to_eLohnausweisSSK' : 'stack_export_to_eLohnausweisSSK_window'

  constructor: (params) ->
    Salary.bind('refresh', @render)
    super

  render: =>
    @html @view('salaries/salaries/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    salary = $(e.target).salary()
    window.location = "/people/#{salary.person_id}?folding=person_salaries"

  destroy: (e) ->
    salary = $(e.target).salary()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications(salary)

  check_as_paid: (e) ->
    salary = $(e.target).salary()
    if confirm(I18n.t('common.are_you_sure'))
      salary.updateAttributes(paid: true)
      Salary.fetch()

  copy_reference: (e) ->
    salary = $(e.target).salary()

    win = Ui.stack_window('salary-copy-reference', {width: 1200, remove_on_close: true})
    controller = new App.DirectoryQueryPresets(el: win, search: { text: I18n.t('salaries.copy_reference') })
    controller.bind 'search', (preset) =>
      Ui.spin_on controller.search.el

      settings =
        url: "#{Salary.url()}/#{salary.id}/copy_reference"
        type: 'POST',
        data: JSON.stringify(query: preset.query)

      ajax_error = (xhr, statusText, error) =>
        Ui.spin_off controller.search.el
        Ui.notify controller.search.el, I18n.t('common.failed_to_update'), 'error'
        controller.search.render_errors $.parseJSON(xhr.responseText)

      ajax_success = (data, textStatus, jqXHR) =>
        Ui.spin_off controller.search.el
        Ui.notify controller.search.el, I18n.t('common.successfully_updated'), 'notice'
        $(win).modal('hide')
        Salary.refresh([], clear: true)
        Salary.fetch()

      Salary.ajax().ajax(settings).error(ajax_error).success(ajax_success)

    $(win).modal({title: I18n.t('salaries.copy_reference')})
    $(win).modal('show')
    controller.activate()

  stack_export_window: (e) ->
    #e.preventDefault()
    #window = Ui.stack_window('export-salaries', {width: 400, remove_on_close: true})
    #controller = new App.ExportSalaries({el: window})
    #$(window).modal({title: I18n.t('salaries.export')})
    #$(window).modal('show')
    #controller.activate()

  stack_export_to_accounting_window: (e) ->
    #e.preventDefault()
    #window = Ui.stack_window('export-accounting-salaries', {width: 400, remove_on_close: true})
    #controller = new App.ExportToAccountingSalaries({el: window})
    #$(window).modal({title: I18n.t('salaries.export_to_accounting')})
    #$(window).modal('show')
    #controller.activate()

  stack_export_to_ocas_window: (e) ->
    #e.preventDefault()
    #window = Ui.stack_window('export-ocas-salaries', {width: 400, remove_on_close: true})
    #controller = new App.ExportToOcasSalaries({el: window})
    #$(window).modal({title: I18n.t('salaries.export_to_ocas')})
    #$(window).modal('show')
    #controller.activate()

  stack_export_to_eLohnausweisSSK_window: (e) ->
    #e.preventDefault()
    #window = Ui.stack_window('export-elohnausweisssk-salaries', {width: 400, remove_on_close: true})
    #controller = new App.ExportToELohnausweisSSKSalaries({el: window})
    #$(window).modal({title: I18n.t('salaries.export_to_elohnausweisssk')})
    #$(window).modal('show')
    #controller.activate()

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
      errors.add [I18n.t("common.from"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add [I18n.t("common.from"), I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add [I18n.t("common.to"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add [I18n.t("common.to"), I18n.t('common.errors.date_must_match_format')].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export')(@)
    Ui.load_ui(@el)

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
      errors.add [I18n.t("common.from"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add [I18n.t("common.from"), I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add [I18n.t("common.to"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add [I18n.t("common.to"), I18n.t('common.errors.date_must_match_format')].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_accounting')(@)
    Ui.load_ui(@el)

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
    year = form.find('#salaries_year').val()

    if year.length == 0
      errors.add [I18n.t("common.year"), I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_ocas')(@)
    Ui.load_ui(@el)

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
    year = form.find('#salaries_year').val()

    if year.length == 0
      errors.add [I18n.t("common.year"), I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @render_errors(errors.errors)

  render: ->
    @html @view('salaries/salaries/export_to_elohnausweisssk')(@)
    Ui.load_ui(@el)

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
    @index.render()
