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
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @search_attribute.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless SearchAttribute.exists(@id)
    @show()
    @search_attribute = SearchAttribute.find(@id)
    @html @view('settings/search_attributes/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @search_attribute.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'search_attribute-edit':      'edit'
    'search_attribute-destroy':   'destroy'

  constructor: (params) ->
    super
    SearchAttribute.bind('refresh', @render)

  render: =>
    @html @view('settings/search_attributes/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    search_attribute = $(e.target).search_attribute()
    @trigger 'edit', search_attribute.id

  destroy: (e) ->
    search_attribute = $(e.target).search_attribute()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications search_attribute

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

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    SearchAttribute.fetch()
    @new.render()
