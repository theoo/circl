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

class ValidatingController extends App.ExtendedController
  elements:
    '#char_counter': 'char_counter'
    'textarea[name="value"]': 'textarea'
    'input[type=submit]': 'submit'

  check_length: (e) ->
    # content_length = $(e.target).val().length
    content_length = @textarea.val().length
    @char_counter.text content_length

    if content_length > 255
      @char_counter.css "font-weight", "bolder"
      @char_counter.css "color", "error"
      @submit.button('disable')
    else
      @char_counter.css "font-weight", "lighter"
      @char_counter.css "color", "rgb(#{content_length},0,0)"
      @submit.button('enable')

class New extends ValidatingController
  events:
    'submit form': 'submit'
    'keyup textarea[name="value"]': 'check_length'

  render: =>
    @application_setting = new ApplicationSetting()
    @html @view('settings/application_settings/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @application_setting.fromForm(e.target), @render

class Edit extends ValidatingController
  events:
    'submit form': 'submit'
    'keyup textarea[name="value"]': 'check_length'

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless ApplicationSetting.exists(@id)
    @show()
    @application_setting = ApplicationSetting.find(@id)
    @html @view('settings/application_settings/form')(@)
    $('input[name="key"]').attr('disabled', 'disabled')
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @application_setting.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'application_setting-edit':      'edit'

  constructor: (params) ->
    super
    ApplicationSetting.bind('refresh', @render)

  render: =>
    @html @view('settings/application_settings/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    application_setting = $(e.target).application_setting()
    @trigger 'edit', application_setting.id

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

  activate: ->
    super
    ApplicationSetting.fetch()
    @new.render()
