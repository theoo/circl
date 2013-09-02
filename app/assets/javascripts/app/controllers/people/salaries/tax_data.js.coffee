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
SalaryTax = App.SalaryTax
SalaryTaxData = App.SalaryTaxData

$.fn.tax_data = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  SalaryTaxData.find(elementID)

class App.SalaryTaxDatas extends Spine.Controller
  className: 'people_salaries_tax_data'

  events:
    'submit form'     : 'submit'
    'click .reset'    : 'reset'
    'click .adjust'   : 'adjust'
    'focus td.tax'    : 'toggle_percentage'

  constructor: (params) ->
    super

    @set_salary(params.salary)

    Salary.bind('refresh', @render)
    SalaryTax.bind('refresh', @render)

  activate: ->
    super
    SalaryTax.fetch()
    @render()

  set_salary: (salary) ->
    @salary = salary
    SalaryTaxData.url = =>
      "#{Spine.Model.host}/people/#{@salary.person_id}/salaries/#{@salary.id}/tax_data"

  render: =>
    @salary = @salary.reload()
    @html @view('people/salaries/common/tax_data')(@)
    Ui.load_ui(@el)
    @select_percentage_or_rough_value()

    sortableTableHelper = (e, ui) ->
      ui.children().each ->
        $(@).width($(@).width());
      return ui

    @el.find('table.category').sortable(
        items: "tr"
        handle: '.handle'
        placeholder: 'placeholder'
        helper: sortableTableHelper
        axis: 'y'
        stop: (event,ui) ->
          $(event.target).find('tr').each (index,value) ->
            tr = $(value)
            pos = tr.data('position')
            position = tr.find("input[name='tax_data[#{pos}][position]']")
            position.attr('value', index)
    )

    if @salary.isNew()
      $(@el).find('input').attr('disabled', true)
      $(@el).fadeTo('slow', 0.3);
    else
      $(@el).find('input').removeAttr('disabled')
      $(@el).fadeTo('slow', 1.0);

  customRenderErrors: (errors) ->
    @render_errors(errors)

    # point rows errors
    for pos, arr of errors
      row = @el.find("#tax_data_#{pos}")

      for messages in arr
        # TODO make this match multiple errors
        matches = messages.match(/(.*):(.*)/)
        attr = matches[1]
        field = row.find("[name='tax_data[#{pos}][#{attr}]']")
        field.parents('td').addClass('field_with_errors')

  name_filter: (str) ->
    (index, item) ->
      name = $(item).attr('name')
      return false unless name
      name.match(str)

  reset: (e) =>
    row   = $(e.target).parents('tr')
    id    = row.find('input').filter(@name_filter('id')).attr('value')

    ajax_error = (xhr, statusText, error) =>
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      for key, value of data
        continue if key.match(/use_percent/)
        field = row.find('input').filter(@name_filter(key))
        field.attr('value', value)
      for str in ['employer_use_percent', 'employee_use_percent']
        value = if data[str] then 1 else 0
        field = row.find('input').filter(@name_filter(str)).filter("[value=#{value}]")
        field.attr('checked', value)

    url = "#{SalaryTaxData.url()}/#{id}/reset"

    settings =
      url: url
      type: 'put'
    SalaryTaxData.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  adjust: (e) =>
    row   = $(e.target).parents('tr')
    id    = row.find('input').filter(@name_filter('id')).attr('value')

    ajax_error = (xhr, statusText, error) =>
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.notify
      for key, value of data
        field = row.find('input').filter(@name_filter(key))
        field.attr('value', value)

    if @salary.is_reference
      url = "#{SalaryTaxData.url()}/#{id}/compute_value_for_next_salaries"
    else
      url = "#{SalaryTaxData.url()}/#{id}/compute_value_for_this_salary"

    data = []
    for str in ['employer_value', 'employee_value']
      input = row.find('input').filter(@name_filter(str))
      data.push("targets[#{str}]=#{input.attr('value')}")

    settings =
      url: url
      type: 'GET'
      data: data.join('&')
    SalaryTaxData.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    ajax_error = (xhr, statusText, error) =>
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      Salary.refresh(data)

    settings =
      url: "#{Salary.url()}/#{@salary.id}/update_tax_data",
      type: 'PUT',
      data: JSON.stringify(attr)
    SalaryTaxData.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  toggle_percentage: (e) ->
    tr = $(e.target).closest('tr')
    pos = tr.data('position')
    td = $(e.target).closest('td')
    $(e.target).addClass('focused')

    if $(e.target).data('type') == 'percentage'
      tr.find("input[name='tax_data[#{pos}][employee_use_percent]'][value='1']").attr('checked', 'checked')
      tr.find("input[name='tax_data[#{pos}][employer_use_percent]'][value='1']").attr('checked', 'checked')
    else
      tr.find("input[name='tax_data[#{pos}][employee_use_percent]'][value='0']").attr('checked', 'checked')
      tr.find("input[name='tax_data[#{pos}][employer_use_percent]'][value='0']").attr('checked', 'checked')

  select_percentage_or_rough_value: ->
    for ee in ['employee', 'employer']
      @el.find("table.category tbody tr").each ->
        pos = $(@).data('position')
        tr = $(@).find("input[name='tax_data[#{pos}][#{ee}_use_percent]']")
        if tr[0]
          if tr.attr('checked')
            $(@).find("input[name='tax_data[#{pos}][#{ee}_percent]']").addClass('selected')
          else
            $(@).find("input[name='tax_data[#{pos}][#{ee}_value]']").addClass('selected')
