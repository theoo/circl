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

Person = App.Person
Permissions = App.Permissions
Language = App.Language

$.fn.item = ->
  elementID   = $(@).data('id')
  elementID or= $(@).parents('[data-id]').data('id')
  Person.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    return unless @can
    @show()
    @person = new Person()
    @html @view('people/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @person.load(data)
    @person.is_an_organization = data.is_an_organization?
    @person.hidden = data.hidden?
    @save_with_notifications @person, (id) =>
      window.location = "people/#{id}"

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    @id = params.id
    Language.bind 'refresh', @render

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    return unless @can && Person.exists(@id)
    @show()
    @person = Person.find(@id)
    @html @view('people/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @person.load(data)
    @person.is_an_organization = data.is_an_organization?
    @person.hidden = data.hidden?
    @save_with_notifications @person, @render

class App.People extends Spine.Controller
  className: 'person'

  constructor: (params) ->
    super

    @person_id = params.person_id

    @edit = new Edit(id: @person_id)
    @new = new New()
    @append(@new, @edit)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

  activate: ->
    super
    Language.fetch()

    if @person_id
      Person.one 'refresh', =>
        @edit.render()

    Permissions.get { person_id: @person_id, can: { person: ['destroy', 'restricted_attributes', 'authenticate_using_token'] }},
                      (data) =>
                        if @person_id?
                          @edit.active { can: data }
                        else
                          @new.active { can: data }
