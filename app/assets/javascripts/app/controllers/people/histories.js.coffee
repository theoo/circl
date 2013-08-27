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

PersonHistory = App.PersonHistory

class Index extends App.ExtendedController
  constructor: (params) ->
    super
    PersonHistory.bind('refresh', @render)

  render: =>
    @histories = PersonHistory.all()
    @html @view('people/histories/index')(@)
    Ui.load_ui(@el)

class App.PersonHistories extends Spine.Controller
  className: 'histories'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonHistory.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/histories"

    @index = new Index
    @append(@index)

  activate: ->
    super
    PersonHistory.fetch()
