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

SearchAttribute = App.SearchAttribute

$.fn.search_attribute = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  SearchAttribute.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @search_attribute = new SearchAttribute()
    @html @view('settings/search_attributes/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @search_attribute.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name=settings-search-attribute-destroy]':   'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @search_attribute = SearchAttribute.find(@id)
    @render()

  render: =>
    @show()
    @html @view('settings/search_attributes/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @search_attribute.fromForm(e.target), @hide

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @search_attribute, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    SearchAttribute.bind('refresh', @render)

  render: =>
    @html @view('settings/search_attributes/index')(@)

  edit: (e) ->
    search_attribute = $(e.target).search_attribute()
    @activate_in_list(e.target)
    @trigger 'edit', search_attribute.id

  table_redraw: =>
    if @search_attribute
      target = $(@el).find("tr[data-id=#{@search_attribute.id}]")

    @activate_in_list(target)

class App.SettingsSearchAttributes extends Spine.Controller
  className: 'search_attributes'

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
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    SearchAttribute.fetch()
    @new.render()
