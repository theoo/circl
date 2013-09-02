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

Location = App.Location

$.fn.location = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @show()
    @location = new Location()
    @html @view('settings/locations/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @location.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless Location.exists(@id)
    @show()
    @location = Location.find(@id)
    @html @view('settings/locations/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @location.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'location-edit':      'edit'
    'location-destroy':   'destroy'

  constructor: (params) ->
    super
    Location.bind('refresh', @render)

  render: =>
    @html @view('settings/locations/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    id = $(e.target).location()
    @trigger 'edit', id

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      id = $(e.target).location()
      Location.one 'refresh', =>
        location = Location.find(id)
        @destroy_with_notifications location

      Location.fetch(id: id)

class App.SettingsLocations extends Spine.Controller
  className: 'locations'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      Location.one 'refresh', =>
        @edit.active(id: id)
      Location.fetch(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'destroyError', (id, errors) =>
      Location.one 'refresh', =>
        @edit.active id: id
        @edit.render_errors errors
      Location.fetch(id: id)

  activate: ->
    super
    @new.render()
    @index.render()
