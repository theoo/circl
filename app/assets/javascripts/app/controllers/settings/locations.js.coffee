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
    'click a[name="reset"]': 'reset'

  constructor: ->
    super

  render: =>
    @show()
    @location = new Location()
    @html @view('settings/locations/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @location.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=settings-location-destroy]': 'destroy'
    'click a[name=settings-location-view-members]': 'view_members'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    Location.one 'refresh', =>
      @location = Location.find(@id)
      @render()
    Location.fetch id: @id

  render: =>
    @show()
    @html @view('settings/locations/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @location.fromForm(e.target)

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @location, @hide

  view_members: (e) ->
    e.preventDefault()
    Directory.search(search_string: "location.id:#{@location.id}")

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    Location.bind('refresh', @render)

  render: =>
    @html @view('settings/locations/index')(@)

  edit: (e) ->
    @id = $(e.target).location()
    @activate_in_list e.target
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

class App.SettingsLocations extends Spine.Controller
  className: 'locations'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      Location.one 'refresh', =>
        @edit.active id: id
        @edit.render_errors errors
      Location.fetch(id: id)

  activate: ->
    super
    Location.fetch()
    @new.render()
