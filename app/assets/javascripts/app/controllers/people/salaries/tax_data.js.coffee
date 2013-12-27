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
PersonSalary = App.PersonSalary
PersonSalaryTaxData = App.PersonSalaryTaxData

$.fn.tax_data = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonSalaryTaxData.find(elementID)

class App.PersonSalaryTaxDatas extends App.ExtendedController
  className: 'person_salary_tax_data'

  events:
    'submit form'     : 'submit'
    'click button[name=reset-tax-data]'    : 'reset'
    'click button[name=adjust-tax-data]'   : 'adjust'
    'focus td input[type=number]'    : 'toggle_percentage'

  constructor: (params) ->
    super
    PersonSalaryTaxData.bind('refresh', @render)

  activate: (params) ->
    super
    if params
      @salary = PersonSalary.find params.salary_id if params.salary_id
    @render()

  render: =>
    @salary ||= [] # placeholder to prevent failure when rendering 'disabled' view.
    # No matter which order is sent from the API, it's not respected
    @tax_data = _.sortBy PersonSalaryTaxData.all(), (d) -> d.position

    @html @view('people/salaries/tax_data')(@)
    @select_percentage_or_rough_value()

    # Keep width
    sortableTableHelper = (e, ui) ->
      ui.children().each ->
        $(@).width($(@).width());
      return ui

    @el.find('table tbody').sortable
        items: "tr"
        handle: '.handle'
        placeholder: 'placeholder'
        helper: sortableTableHelper
        axis: 'y'
        start: (event, ui) ->
          height = $(@).find('tr:first').height()
          placeholder = $(@).find('.placeholder')
          placeholder.css(height: height)
          placeholder.addClass 'warning'
        stop: (event,ui) ->
          $(event.target).find('tr').each (index,value) ->
            tr = $(value)
            pos = tr.data('position')
            position = tr.find("input[name='tax_data[#{pos}][position]']")
            position.attr('value', index)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonSalaryTaxData.url() == undefined

  name_filter: (str) ->
    (index, item) ->
      name = $(item).attr('name')
      return false unless name
      name.match(str)

  reset: (e) =>
    row   = $(e.target).parents('tr')
    id    = row.find('input').filter(@name_filter('id')).attr('value')

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @render_success()
      for key, value of data
        continue if key.match(/use_percent/)
        field = row.find('input').filter(@name_filter(key))
        field.attr('value', value)
      for str in ['employer_use_percent', 'employee_use_percent']
        value = if data[str] then 1 else 0
        field = row.find('input').filter(@name_filter(str)).filter("[value=#{value}]")
        field.attr('checked', value)

    url = "#{PersonSalaryTaxData.url()}/#{id}/reset"

    settings =
      url: url
      type: 'put'
    PersonSalaryTaxData.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  adjust: (e) =>
    row   = $(e.target).parents('tr')
    id    = row.find('input').filter(@name_filter('id')).attr('value')

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @render_success()
      for key, value of data
        field = row.find('input').filter(@name_filter(key))
        field.attr('value', value)

    if @salary.is_reference
      url = "#{PersonSalaryTaxData.url()}/#{id}/compute_value_for_next_salaries"
    else
      url = "#{PersonSalaryTaxData.url()}/#{id}/compute_value_for_this_salary"

    data = []
    for str in ['employer_value', 'employee_value']
      input = row.find('input').filter(@name_filter(str))
      data.push("targets[#{str}]=#{input.attr('value')}")

    settings =
      url: url
      type: 'GET'
      data: data.join('&')
    PersonSalaryTaxData.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @render_success()
      # Retrive salary totals (which are computed Rails side)
      PersonSalary.one 'refresh', =>
        @salary = PersonSalary.find @salary.id
        # Then refresh tax_data
        PersonSalaryTaxData.refresh(data.tax_data)
      PersonSalary.refresh(data)

    settings =
      url: "#{PersonSalary.url()}/#{@salary.id}/update_tax_data",
      type: 'PUT',
      data: JSON.stringify(attr)
    PersonSalaryTaxData.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  toggle_percentage: (e) ->
    tr = $(e.target).closest('tr')
    pos = tr.data('position')
    td = $(e.target).closest('td')
    td.addClass('warning')

    if $(e.target).data('type') == 'percentage'
      tr.find("input[name='tax_data[#{pos}][employee_use_percent]'][value='1']").prop('checked', true)
      tr.find("input[name='tax_data[#{pos}][employer_use_percent]'][value='1']").prop('checked', true)
    else
      tr.find("input[name='tax_data[#{pos}][employee_use_percent]'][value='0']").prop('checked', true)
      tr.find("input[name='tax_data[#{pos}][employer_use_percent]'][value='0']").prop('checked', true)

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
