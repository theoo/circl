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
SalarySalaryTemplate = App.SalarySalaryTemplate

class App.SalaryDetails extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super
    SalarySalaryTemplate.bind('refresh', @render)
    Salary.bind('refresh', @render)

  activate: ->
    super
    SalarySalaryTemplate.fetch()
    @render()

  render: =>
    @show()
    @html @view('people/salaries/common/details')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    was_new = @salary.isNew()

    data = $(e.target).serializeObject()
    @salary.load(data)

    @salary.married = data.married?
    @salary.paid = data.paid?

    @save_with_notifications @salary, (id) =>
      if was_new
        @salary = Salary.find(id)
        @trigger 'edit', @salary
        @render()
