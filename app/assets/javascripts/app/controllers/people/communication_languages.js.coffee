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
Person = App.Person
PersonCommunicationLanguage = App.PersonCommunicationLanguage
Language = App.Language

$.fn.subscription = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Language.find(elementID)

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    PersonCommunicationLanguage.bind 'refresh', @render
    Language.bind 'refresh', @render

  has_communication_language: (id) =>
    for lang in PersonCommunicationLanguage.all()
      if lang.id == id
        return true
    false

  render: =>
    @html @view('people/communication_languages/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    Ui.spin_on @el
    e.preventDefault()
    attr = $(e.target).serializeObject()

    ajax_error = (xhr, statusText, error) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @renderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      # Store the modifications in Spine
      PersonCommunicationLanguage.refresh(data, clear: true)

    settings =
      url: PersonCommunicationLanguage.url(),
      type: 'PUT',
      data: JSON.stringify(attr)
    PersonCommunicationLanguage.ajax().ajax(settings).error(ajax_error).success(ajax_success)

class App.PersonCommunicationLanguages extends Spine.Controller
  className: 'communication_languages'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonCommunicationLanguage.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/communication_languages"

    @edit = new Edit
    @append(@edit)

  activate: ->
    super
    PersonCommunicationLanguage.fetch()
    Language.fetch()
