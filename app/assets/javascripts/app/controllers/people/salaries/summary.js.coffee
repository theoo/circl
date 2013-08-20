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

$ = jQuery.sub()
Salary = App.Salary

class App.SalarySummary extends Spine.Controller
  className: 'people_salaries_summary'

  constructor: (params) ->
    super
    @set_salary(params.salary)
    Salary.bind('refresh', @render)

  set_salary: (salary) ->
    @salary = salary

  render: =>
    @salary = @salary.reload()
    @html @view('people/salaries/common/summary')(@)
    Ui.load_ui(@el)
    if @salary.isNew()
      $(@el).find('input').attr('disabled', true)
      $(@el).fadeTo('slow', 0.3);
    else
      $(@el).find('input').removeAttr('disabled')
      $(@el).fadeTo('slow', 1.0);

  activate: ->
    super
    @render()
