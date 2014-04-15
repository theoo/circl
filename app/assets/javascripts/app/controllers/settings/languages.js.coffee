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

Language = App.Language

$.fn.language = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Language.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  render: =>
    @language = new Language()
    @html @view('settings/languages/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @language.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name="cancel"]': 'cancel'
    'click button[name=settings-language-destroy]': 'destroy'
    'click a[name=settings-language-view-main-members]': 'view_main_members'
    'click a[name=settings-language-view-members]': 'view_members'

  active: (params) ->
    @id = params.id if params.id
    @language = Language.find(@id)
    @render()

  render: =>
    @show()
    @html @view('settings/languages/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @language.fromForm(e.target)

  view_main_members: (e) ->
    e.preventDefault()
    Directory.search(search_string: "main_communication_language.id:#{@language.id}")

  view_members: (e) ->
    e.preventDefault()
    Directory.search(search_string: "communication_languages.id:#{@language.id}")

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @language, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    Language.bind('refresh', @render)

  render: =>
    @html @view('settings/languages/index')(@)

  edit: (e) ->
    @language = $(e.target).language()
    @activate_in_list e.target
    @trigger 'edit', @language.id

  table_redraw: =>
    if @language
      target = $(@el).find("tr[data-id=#{@language.id}]")

    @activate_in_list(target)

class App.SettingsLanguages extends Spine.Controller
  className: 'languages'

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
    Language.fetch()
    @new.render()
