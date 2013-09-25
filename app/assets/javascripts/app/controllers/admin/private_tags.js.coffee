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

$.fn.private_tag = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PrivateTag.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @tag = new PrivateTag()
    @html @view('admin/private_tags/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @tag.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name=tag-view-members]':   'view_members'
    'click a[name=tag-add-members]':    'add_members'
    'click a[name=tag-remove-members]': 'remove_members'
    'click button[name=tag-destroy]':        'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @tag = PrivateTag.find(@id)
    @render()

  render: =>
    return unless PrivateTag.exists(@id)
    @show()
    @html @view('admin/private_tags/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @tag.fromForm(e.target), @hide

  view_members: (e) ->
    e.preventDefault()
    App.search_query(search_string: "private_tags.id:#{@tag.id}")

  add_members: (e) ->
    e.preventDefault()
    win = $("<div class='modal fade' id='invoice-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('tag.views.actions.add_members') + ": " + @tag.name

    # Adapt width to A4
    win.find('.modal-dialog')

    # Add preview in new tab button
    btn = "<button type='button' name='search' class='btn btn-default'>"
    btn += I18n.t('directory.actions.search')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonAffairInvoice.url()}/#{@invoice.id}.html", "_blank"

    controller = new App.DirectoryQueryPresets(el: win.find('.modal-body'))
    controller.bind 'search', (preset) =>

      settings =
        url: "#{PrivateTag.url()}/#{@tag.id}/add_members"
        type: 'POST',
        data: JSON.stringify(query: preset.query)

      ajax_error = (xhr, statusText, error) =>
        controller.search.render_errors $.parseJSON(xhr.responseText)

      ajax_success = (data, textStatus, jqXHR) =>
        $(win).modal('hide')
        PrivateTag.fetch(id: @tag.id)

      PrivateTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

    win.modal('show')
    controller.activate()

  remove_members: (e) ->
    e.preventDefault()
    settings =
      url: "#{PrivateTag.url()}/#{@tag.id}/remove_all_members"
      type: 'POST'

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      # Refresh member dropdown
      PrivateTag.one 'refresh', =>
        @active(id: @tag.id)

      PrivateTag.fetch(id: @tag.id)

    if confirm(I18n.t('common.are_you_sure'))
      PrivateTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @tag, =>
        @hide()

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    PrivateTag.bind('refresh', @render)

  active: (params) ->
    if params
      @person_id = params.person_id
      @tag = PrivateTag.find(params.id)
    @render()

  render: =>
    @html @view('admin/private_tags/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    tag = $(e.target).private_tag()
    @activate_in_list(e.target)
    @trigger 'edit', tag.id

  table_redraw: =>
    if @tag
      target = $(@el).find("tr[data-id=#{@tag.id}]")

    @activate_in_list(target)

class App.AdminPrivateTags extends Spine.Controller
  className: 'private_tags'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'edit', (id) =>
      @edit.active(id: id)
      @index.active(id: id)

    @edit.bind 'destroyError', (id, errors) =>
      @edit.render_errors errors

  activate: ->
    super
    PrivateTag.fetch()
    @new.render()
