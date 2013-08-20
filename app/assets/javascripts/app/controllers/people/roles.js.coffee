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
PersonRole = App.PersonRole
Role = App.Role

$.fn.role = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonRole.find(elementID)

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
    Ui.load_ui(@el)

  update: (e) =>
    Ui.spin_on(@el)
    e.preventDefault()
    ids = $(e.target).find('input:checked').map( -> return $(@).attr('value') ).toArray()

    settings =
      url: PersonRole.url(),
      type: 'PUT',
      data: {ids: ids}

    ajax_error = (xhr, statusText, error) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @renderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      PersonRole.refresh(data, {clear: true})
      @render()

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
