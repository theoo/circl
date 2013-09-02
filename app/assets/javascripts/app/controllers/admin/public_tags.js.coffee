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

$.fn.tag = ->
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
    return unless PublicTag.exists(@id)
    @show()
    @tag = PublicTag.find(@id)
    @html @view('admin/public_tags/form')(@)
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
    PublicTag.bind('refresh', @render)

  render: =>
    @html @view('admin/public_tags/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    tag = $(e.target).tag()
    @trigger 'edit', tag.id

  view_members: (e) ->
    tag = $(e.target).tag()
    App.search_query(search_string: "public_tags.id:#{tag.id}")

  add_members: (e) ->
    tag = $(e.target).tag()
    win = Ui.stack_window('tag-add-members-window', {width: 1200, remove_on_close: true})
    controller = new App.DirectoryQueryPresets(el: win, search: { text: I18n.t('directory.views.add_to_tag') })
    controller.bind 'search', (preset) =>
      Ui.spin_on controller.search.el

      settings =
        url: "#{PublicTag.url()}/#{tag.id}/add_members"
        type: 'POST',
        data: JSON.stringify(query: preset.query)

      ajax_error = (xhr, statusText, error) =>
        Ui.spin_off controller.search.el
        Ui.notify controller.search.el, I18n.t('common.failed_to_update'), 'error'
        controller.search.render_errors $.parseJSON(xhr.responseText)

      ajax_success = (data, textStatus, jqXHR) =>
        Ui.spin_off controller.search.el
        Ui.notify controller.search.el, I18n.t('common.successfully_updated'), 'notice'
        $(win).modal('hide')
        PublicTag.fetch(id: tag.id)

      PublicTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

    $(win).modal({title: I18n.t('tag.views.contextmenu.add_members')})
    $(win).modal('show')
    controller.activate()

  remove_members: (e) ->
    tag = $(e.target).tag()

    settings =
      url: "#{PublicTag.url()}/#{tag.id}/remove_all_members"
      type: 'POST'

    ajax_error = (xhr, statusText, error) =>
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      PublicTag.fetch(id: tag.id)

    if confirm(I18n.t('common.are_you_sure'))
      PublicTag.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  destroy: (e) ->
    tag = $(e.target).tag()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications tag

class App.AdminPublicTags extends Spine.Controller
  className: 'public_tags'

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
      @edit.render_errors errors

  activate: ->
    super
    PublicTag.fetch()
    @new.render()
