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
SalaryItem = App.SalaryItem

class App.SalaryItems extends App.ExtendedController

  className: 'people_salaries_items'

  events:
    'submit form'    : 'submit'
    'click .adjust'  : 'adjust'
    'click .remove'  : 'remove'

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
    SalaryItem.url = =>
      "#{Spine.Model.host}/people/#{@salary.person_id}/salaries/#{@salary.id}/items"

  render: =>
    @salary = @salary.reload()
    @html @view('people/salaries/common/items')(@)
    Ui.load_ui(@el)

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
          $(@).find('tr').each (index,value) ->
            tr = $(value)
            pos = tr.data('position')
            position = tr.find("input[name='items[#{pos}][position]']")
            position.attr('value', index)
    )

    if @salary.isNew()
      $(@el).find('input').attr('disabled', true)
      $(@el).fadeTo('slow', 0.3);
    else
      $(@el).find('input').removeAttr('disabled')
      $(@el).fadeTo('slow', 1.0);

  name_filter: (str) ->
    (index, item) ->
      name = $(item).attr('name')
      return false unless name
      name.match(str)

  remove: (e) =>
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
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      for key, value of data
        field = row.find('input').filter(@name_filter(key))
        field.attr('value', value)

    if @salary.is_reference
      url = "#{SalaryItem.url()}/#{id}/compute_value_for_next_salaries"
    else
      url = "#{SalaryItem.url()}/#{id}/compute_value_for_this_salary"

    settings =
      url: url
      type: 'GET'
      data: "target=#{input.attr('value')}"
    SalaryItem.ajax().ajax(settings).error(ajax_error).success(ajax_success)

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
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @customRenderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      Salary.refresh(data)

    settings =
      url: "#{Salary.url()}/#{@salary.id}/update_items",
      type: 'PUT',
      data: JSON.stringify(attr)
    SalaryItem.ajax().ajax(settings).error(ajax_error).success(ajax_success)
