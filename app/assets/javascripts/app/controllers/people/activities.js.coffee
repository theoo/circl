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

PersonActivity = App.PersonActivity

class Index extends App.ExtendedController
  constructor: (params) ->
    super
    PersonActivity.bind('refresh', @render)

  render: =>
    @activities = PersonActivity.all()
    @html @view('people/activities/index')(@)
    Ui.load_ui(@el)

class App.PersonActivities extends Spine.Controller
  className: 'activities'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonActivity.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/activities"

    @index = new Index
    @append(@index)

  activate: ->
    super
    PersonActivity.fetch()
