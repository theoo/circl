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
PersonSalaryItem = App.PersonSalaryItem
PersonSalaryTaxData = App.PersonSalaryTaxData

class App.PersonSalaryItems extends App.ExtendedController
  className: 'person_salary_items'

  events:
    'submit form'    : 'submit'
    'click button[name=adjust-item]'  : 'adjust'
    'click button[name=destroy-item]'  : 'destroy'

  constructor: (params) ->
    super
    PersonSalaryItem.bind 'refresh', @render

  activate: (params) ->
    super
    if params
      @salary = PersonSalary.find params.salary_id if params.salary_id

    @render()

  render: =>
    @items = PersonSalaryItem.all()
    @html @view('people/salaries/items')(@)

    # Keep width
    sortableTableHelper = (e, ui) ->
      ui.children().each ->
        $(@).width($(@).width());
      return ui

    # FIXME doesn't keep position
    @el.find('table tbody').sortable
        items: "tr"
        handle: '.handle'
        helper: sortableTableHelper
        placeholder: 'placeholder'
        axis: 'y'
        start: (event, ui) ->
          height = $(@).find('tr:first').height()
          placeholder = $(@).find('.placeholder')
          placeholder.css(height: height)
          placeholder.addClass 'warning'
        stop: (event, ui) ->
          $(@).find('tr').each (index, value) ->
            tr = $(value)
            pos = tr.data('position')
            position = tr.find("input[name='items[#{pos}][position]']")
            position.attr('value', index)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonSalaryItem.url() == undefined

  name_filter: (str) ->
    (index, item) ->
      name = $(item).attr('name')
      return false unless name
      name.match(str)

  destroy: (e) =>
    $(e.target).parents('tr').remove()
    @set_correct_positions()

  set_correct_positions: =>
    reorder = (index, item) =>
      $(item).find('input').filter(@name_filter('position')).attr('value', index)
    $(@el).find('tr').filter(reorder)

  adjust: (e) =>
    row   = $(e.target).parents('tr')
    id    = row.find('input').filter(@name_filter('id')).attr('value')
    input = row.find('input').filter(@name_filter('value'))

    ajax_error = (xhr, statusText, error) =>
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      for key, value of data
        field = row.find('input').filter(@name_filter(key))
        field.attr('value', value)

    if @salary.is_reference
      url = "#{PersonSalaryItem.url()}/#{id}/compute_value_for_next_salaries"
    else
      url = "#{PersonSalaryItem.url()}/#{id}/compute_value_for_this_salary"

    settings =
      url: url
      type: 'GET'
      data: "target=#{input.attr('value')}"
    PersonSalaryItem.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  customRenderErrors: (errors) ->
    @render_errors(errors)

    # point rows with errors
    for desc, arr of errors
      pos = parseInt(desc.match(/line (\d+)/)[1])
      row = $($(@el).find('tr')[pos])

      for messages in arr
        # TODO make this match multiple errors
        matches = messages.match(/(.*):(.*)/)
        attr = matches[1]
        input = row.find('input').filter(@name_filter(attr))
        input.parents('td').addClass('field_with_errors')

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    ajax_error = (xhr, statusText, error) =>
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      PersonSalary.refresh([], clear: true)
      PersonSalary.fetch()
      PersonSalaryItem.refresh([], clear: true)
      PersonSalaryItem.fetch()
      PersonSalaryTaxData.refresh([], clear: true)
      PersonSalaryTaxData.fetch()

    settings =
      url: "#{PersonSalary.url()}/#{@salary.id}/update_items",
      type: 'PUT',
      data: JSON.stringify(attr)
    PersonSalaryItem.ajax().ajax(settings).error(ajax_error).success(ajax_success)
