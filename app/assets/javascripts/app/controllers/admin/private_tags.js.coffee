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

$.fn.tag = ->
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

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless PrivateTag.exists(@id)
    @show()
    @tag = PrivateTag.find(@id)
    @html @view('admin/private_tags/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @tag.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'tag-edit':           'edit'
    'tag-members':        'view_members'
    'tag-add-members':    'add_members'
    'tag-remove-members': 'remove_members'
    'tag-destroy':        'destroy'

  constructor: (params) ->
    super
    PrivateTag.bind('refresh', @render)

  render: =>
    @html @view('admin/private_tags/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    tag = $(e.target).tag()
    @trigger 'edit', tag.id

  view_members: (e) ->
    tag = $(e.target).tag()
    App.search_query(search_string: "private_tags.id:#{tag.id}")

  add_members: (e) ->
    tag = $(e.target).tag()
    win = Ui.stack_window('tag-add-members-window', {width: 1200, remove_on_close: true})
    controller = new App.DirectoryQueryPresets(el: win, search: { text: I18n.t('directory.views.add_to_tag') })
    controller.bind 'search', (preset) =>
      Ui.spin_on controller.search.el

      settings =
        url: "#{PrivateTag.url()}/#{tag.id}/add_members"
        type: 'POST',
        data: JSON.stringify(query: preset.query)

      ajax_error = (xhr, statusText, error) =>
        Ui.spin_off controller.search.el
        Ui.notify controller.search.el, I18n.t('common.failed_to_update'), 'error'
        controller.search.renderErrors $.parseJSON(xhr.responseText)

      ajax_success = (data, textStatus, jqXHR) =>
        Ui.spin_off controller.search.el
        Ui.notify controller.search.el, I18n.t('common.successfully_updated'), 'notice'
        $(win).modal('hide')
        PrivateTag.fetch(id: tag.id)

      PrivateTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

    $(win).modal({title: I18n.t('tag.views.contextmenu.add_members')})
    $(win).modal('show')
    controller.activate()

  remove_members: (e) ->
    tag = $(e.target).tag()

    settings =
      url: "#{PrivateTag.url()}/#{tag.id}/remove_all_members"
      type: 'POST'

    ajax_error = (xhr, statusText, error) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @renderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      PrivateTag.fetch(id: tag.id)

    if confirm(I18n.t('common.are_you_sure'))
      PrivateTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  destroy: (e) ->
    tag = $(e.target).tag()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications tag

class App.AdminPrivateTags extends Spine.Controller
  className: 'private_tags'

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

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    PrivateTag.fetch()
    @new.render()
