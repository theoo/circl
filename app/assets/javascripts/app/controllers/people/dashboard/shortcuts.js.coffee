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

class Index extends App.ExtendedController
  events:
    'submit form.dashboard_shortcuts_person': 'select_person'
    'submit form.dashboard_shortcuts_affair': 'select_affair'

  constructor: (params) ->
    super

  render: =>
    @html @view('people/dashboard/shortcuts')(@)

  select_person: (e) ->
    e.preventDefault()
    id = @el.find("input[name='dashboard_shortcuts_person_id']").val()
    if id
      window.location = "#{Spine.Model.host}/people/#{id}"

  select_affair: (e) ->
    e.preventDefault()
    id = @el.find("input[name='dashboard_shortcuts_affair_id']").val()
    if id
      window.location = "#{Spine.Model.host}/admin/affairs/#{id}"

class App.DashboardShortcuts extends Spine.Controller
  className: 'shortcuts'

  constructor: (params) ->
    super
    @person_id = params.person_id

    @index = new Index
    @append(@index)

  activate: ->
    super
    @index.render()
