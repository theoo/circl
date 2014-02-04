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

PrivateTag = App.PrivateTag
PersonPrivateTag = App.PersonPrivateTag

$.fn.tag = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonPrivateTag.find(elementID)

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    PrivateTag.bind('refresh', @render)
    PersonPrivateTag.bind('refresh', @render)
    super

  render: =>
    # Get root tags
    @root_tags = _(tag for tag in PrivateTag.all() when !tag.parent_id?).sortBy (a) -> a.name
    @html @view('people/private_tags/form')(@)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    settings =
      url: PersonPrivateTag.url(),
      type: 'PUT',
      data: JSON.stringify(attr)

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @render_success()

    PersonPrivateTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

class App.PersonPrivateTags extends Spine.Controller
  className: 'private_tags'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonPrivateTag.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/private_tags"

    @edit = new Edit
    @append(@edit)

  activate: ->
    super
    PersonPrivateTag.fetch()
    PrivateTag.fetch()
