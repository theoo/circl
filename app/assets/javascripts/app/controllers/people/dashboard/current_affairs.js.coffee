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

Affair = App.Affair

class Index extends App.ExtendedController
  events:
    'click tr.item': 'show'

  constructor: (params) ->
    super
    Affair.bind('refresh', @render)

  render: =>
    # Spine orders by ID, no matter what server sends.
    @affairs = Affair.all()
    @html @view('people/dashboard/current_affairs')(@)

  show: (e) ->
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    window.location = "#{Spine.Model.host}/people/#{id}#affairs"

class App.DashboardCurrentAffairs extends Spine.Controller
  className: 'current_affairs'

  constructor: (params) ->
    super
    @person_id = params.person_id

    Affair.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/dashboard/current_affairs"

    @index = new Index
    @append(@index)

  activate: ->
    super
    Affair.fetch()
