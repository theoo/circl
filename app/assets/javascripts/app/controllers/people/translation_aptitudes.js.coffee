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
Language = App.Language
PersonTranslationAptitude = App.PersonTranslationAptitude

$.fn.translation = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonTranslationAptitude.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    Language.bind('refresh', @render)

  render: =>
    @show()
    @translation = new PersonTranslationAptitude
    @html @view('people/translation_aptitudes/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @translation.fromForm(e.target), @render

class Index extends App.ExtendedController
  events:
    'translation-destroy': 'destroy'

  constructor: (params) ->
    super
    Language.bind('refresh', @render)
    PersonTranslationAptitude.bind('refresh', @render)

  active: (params) ->
    @render()

  render: =>
    @html @view('people/translation_aptitudes/index')(@)
    Ui.load_ui(@el)

  destroy: (e) ->
    translation = $(e.target).translation()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications translation

class App.PersonTranslationAptitudes extends Spine.Controller
  className: 'translation_aptitudes'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonTranslationAptitude.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/translation_aptitudes"

    @index = new Index
    @new = new New(person_id: @person_id)
    @append(@new, @index)

    @index.bind 'destroyError', (id, errors) =>
      @new.active id: id
      @new.renderErrors errors

  activate: ->
    super
    Language.fetch()
    PersonTranslationAptitude.fetch()
    @new.render()
