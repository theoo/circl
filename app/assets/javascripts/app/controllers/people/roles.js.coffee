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

PersonRole = App.PersonRole
Role = App.Role

class Index extends App.ExtendedController
  events:
    'submit form': 'update'

  constructor: (params) ->
    super
    PersonRole.bind('refresh', @render)
    Role.bind('refresh', @render)

  render: =>
    @show()
    @html @view('people/roles/index')(@)

  update: (e) =>
    e.preventDefault()
    ids = $(e.target).find('input:checked').map( -> return $(@).attr('value') ).toArray()

    settings =
      url: PersonRole.url(),
      type: 'PUT',
      data: {ids: ids}

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @render_success()
      # Update badge
      $('a[href=#permissions_tab] .badge').html ids.length

    # TODO make this send JSON params instead of HTML form params
    Spine.Ajax.queue =>
      $.ajax(settings).error(ajax_error).success(ajax_success)

class App.PersonRoles extends Spine.Controller
  className: 'roles'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonRole.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/roles"

    @index = new Index
    @append(@index)

  activate: ->
    super
    Role.fetch()
    PersonRole.fetch()
