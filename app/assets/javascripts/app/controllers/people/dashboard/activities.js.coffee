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
    # Spine orders by ID, no matter what server sends.
    @activities = _.sortBy(PersonActivity.all(), (d) -> d.created_at).reverse()
    @html @view('people/dashboard/activities')(@)
    $(@el).find('tr').each (index, tr) ->
      $(tr).popover()

class App.DashboardActivities extends Spine.Controller
  className: 'activities'

  constructor: (params) ->
    super
    @person_id = params.person_id

    PersonActivity.url = =>
      "/people/#{@person_id}/dashboard/activities"

    @index = new Index
    @append(@index)

  activate: ->
    super
    PersonActivity.fetch()
