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

ApplicationSetting = App.ApplicationSetting

$.fn.application_setting = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  ApplicationSetting.find(elementID)

class New extends App.ExtendedController

  render: =>
    @application_setting = new ApplicationSetting()
    @html @view('settings/application_settings/form')(@)

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'

  active: (params) ->
    @id = params.id if params.id
    @application_setting = ApplicationSetting.find(@id)
    @render()

  render: =>
    return unless ApplicationSetting.exists(@id)
    @show()
    @html @view('settings/application_settings/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @application_setting.fromForm(e.target)

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    ApplicationSetting.bind('refresh', @render)

  render: =>
    @html @view('settings/application_settings/index')(@)

  edit: (e) ->
    e.preventDefault()
    @application_setting = $(e.target).application_setting()
    @activate_in_list(e.target)
    @trigger 'edit', @application_setting.id

  table_redraw: =>
    if @application_setting
      target = $(@el).find("tr[data-id=#{@application_setting.id}]")

    @activate_in_list(target)

class App.SettingsApplicationSettings extends Spine.Controller
  className: 'application_settings'

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
    ApplicationSetting.fetch()
    @new.render()
