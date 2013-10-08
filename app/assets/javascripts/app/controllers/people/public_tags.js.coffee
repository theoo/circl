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

PublicTag = App.PublicTag
PersonPublicTag = App.PersonPublicTag

$.fn.tag = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonPublicTag.find(elementID)

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    PublicTag.bind('refresh', @render)
    PersonPublicTag.bind('refresh', @render)
    super

  render: =>
    # Get root tags
    @root_tags = _(tag for tag in PublicTag.all() when !tag.parent_id?).sortBy (a) -> a.name
    @html @view('people/public_tags/form')(@)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    settings =
      url: PersonPublicTag.url(),
      type: 'PUT',
      data: JSON.stringify(attr)

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @render_success()
      # Store the modifications in Spine
      PersonPublicTag.refresh(data, clear: true)

    PersonPublicTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

class App.PersonPublicTags extends Spine.Controller
  className: 'public_tags'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonPublicTag.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/public_tags"

    @edit = new Edit
    @append(@edit)

  activate: ->
    super
    PersonPublicTag.fetch()
    PublicTag.fetch()
