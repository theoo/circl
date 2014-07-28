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

$.fn.public_tag = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PublicTag.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @tag = new PublicTag()
    @html @view('admin/public_tags/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @tag.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=tag-destroy]':   'destroy'
    'click a[name=tag-view-members]':   'view_members'
    'click a[name=tag-add-members]':    'add_members'
    'click a[name=tag-remove-members]': 'remove_members'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @tag = PublicTag.find(@id)
    @render()

  render: =>
    return unless PublicTag.exists(@id)
    @show()
    @html @view('admin/public_tags/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @tag.fromForm(e.target)

  view_members: (e) ->
    e.preventDefault()
    Directory.search(search_string: "public_tags.id:#{@tag.id}")

  add_members: (e) ->
    e.preventDefault()

    query       = new App.QueryPreset
    url         = "#{PublicTag.url()}/#{@tag.id}/add_members"
    title       = I18n.t('tag.views.add_members_title') + " <i>" + @tag.name + "</i>"
    message     = I18n.t('tag.views.add_members_message')

    Directory.search_with_custom_action query,
      url: url
      title: title
      message: message

  remove_members: (e) ->
    e.preventDefault()

    settings =
      url: "#{PublicTag.url()}/#{@tag.id}/remove_all_members"
      type: 'POST'

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      PublicTag.fetch(id: @tag.id)

    if confirm(I18n.t('common.are_you_sure'))
      PublicTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @tag, (id) =>
        @hide()

class Index extends App.ExtendedController
  events:
    'click tr.item':    'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    PublicTag.bind('refresh', @render)

  active: (params) ->
    if params
      @person_id = params.person_id
      @tag = PublicTag.find(params.id)
    @render()

  render: =>
    @html @view('admin/public_tags/index')(@)

  edit: (e) ->
    e.preventDefault()
    tag = $(e.target).public_tag()
    @activate_in_list(e.target)
    @trigger 'edit', tag.id

  table_redraw: =>
    if @tag
      target = $(@el).find("tr[data-id=#{@tag.id}]")

    @activate_in_list(target)

class App.AdminPublicTags extends Spine.Controller
  className: 'public_tags'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @index.active(id: id)
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    PublicTag.fetch()
    @new.render()
