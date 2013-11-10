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

TaskRate = App.TaskRate

class Index extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    @person_id = $('#person_id').val()
    @person = App.Person.find @person_id
    TaskRate.bind('refresh', @render)

  render: =>
    @html @view('people/affairs/task_rates/index')(@)

  submit: (e) ->
    e.preventDefault()
    @person.task_rate_id = $("#person_affair_task_rate_id").val()
    @save_with_notifications @person

class App.PersonAffairTaskRates extends Spine.Controller
  className: 'person_affair_task_rates'

  constructor: (params) ->
    super

    @person_id = params.person_id

    @index = new Index
    @append(@index)

  activate: ->
    super
    TaskRate.fetch()
