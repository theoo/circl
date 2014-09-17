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

PersonComment = App.PersonComment

$.fn.comment_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  elementID

LocalUi =
  update_badge: ->
    PersonComment.one 'count_fetched', ->
      $('a[href=#activities_tab] .badge').html PersonComment.count()
    PersonComment.fetch_count()

class New extends App.ExtendedController

  @include LocalUi

  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  render: =>
    @comment = new PersonComment(resource_id: @person_id)
    @html @view('people/comments/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @comment.fromForm(e.target), =>
      @render()
      @update_badge()

class Edit extends App.ExtendedController

  @include LocalUi

  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name="comment-reopen"]': 'reopen'
    'click button[name="comment-close"]': 'close'
    'click button[name="comment-destroy"]': 'destroy'
    'click a[name="reset"]': 'reset'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonComment.exists(@id)
    @show()
    @comment = PersonComment.find(@id)
    @html @view('people/comments/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @comment.fromForm(e.target), @hide

  reopen: (e) ->
    e.preventDefault()
    @comment.is_closed = false
    @save_with_notifications @comment

  close: (e) ->
    e.preventDefault()
    @comment.is_closed = true
    @save_with_notifications @comment

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications @comment, =>
        @hide()
        @update_badge()


class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    PersonComment.bind('refresh', @render)

  render: =>
    @html @view('people/comments/index')(@)

  table_redraw: =>
    if @comment
      target = $(@el).find("tr[data-id=#{@comment.id}]")

    @activate_in_list(target)

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).comment_id()

    PersonComment.one 'refresh', =>
      @comment = PersonComment.find(id)
      @activate_in_list(e.target)
      @trigger 'edit', @comment.id

    PersonComment.fetch(id: id)

class App.PersonComments extends Spine.Controller
  className: 'comments'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonComment.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/comments"

    @index = new Index
    @edit = new Edit
    @new = new New(person_id: @person_id)
    @append(@new, @edit, @index)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active(id: id)
      @edit.render_errors errors

  activate: ->
    super
    PersonComment.fetch()
    @new.render()
