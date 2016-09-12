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

Role = App.Role
Permission = App.Permission
RolePermission = App.RolePermission

# .role method is used by jQuery Ui and may conflict
$.fn.get_role = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Role.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="reset"]': 'reset'

  constructor: ->
    super

  render: =>
    @role = new Role()
    @html @view('settings/roles/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @role.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=settings-role-destroy]': 'destroy'
    'click button[name=settings-role-view-members]': 'view_members'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @role = Role.find(@id)
    @load_dependencies()
    @render()

  render: =>
    @html @view('settings/roles/form')(@)
    @show()

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @role.fromForm(e.target)

  cancel: (e) ->
    e.preventDefault()
    @unload_dependencies()
    super(e)

  destroy: (e) ->
    e.preventDefault()
    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      @destroy_with_notifications @role, @hide

  view_members: (e) ->
    e.preventDefault()
    Directory.search(search_string: "roles.id:#{@role.id}")

  load_dependencies: ->
    if @id
      permissions_controller = $("#settings_role_permissions").data("controller")
      permissions_controller.activate(role_id: @id)

      RolePermission.url = =>
       "/settings/roles/#{@id}/permissions"

      RolePermission.refresh([], clear: true)
      RolePermission.fetch()
      Permission.refresh([], clear: true)
      Permission.fetch()


  unload_dependencies: ->
    RolePermission.url = => undefined
    RolePermission.refresh([], clear: true)
    Permission.refresh([], clear: true)

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=settings-roles-reindexing-notice]': "redirect_to_search_attributes"

  constructor: (params) ->
    super
    Role.bind('refresh', @render)

  render: =>
    @html @view('settings/roles/index')(@)

  edit: (e) ->
    e.preventDefault()
    @role = $(e.target).get_role()
    @activate_in_list(e.target)
    @trigger 'edit', @role.id

  table_redraw: =>
    if @role
      target = $(@el).find("tr[data-id=#{@role.id}]")

    @activate_in_list(target)

  redirect_to_search_attributes: (e) ->
    e.preventDefault()
    $("a[href=#searchengine_tab]").click()

class App.SettingsRoles extends Spine.Controller
  className: 'roles'

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

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    Role.fetch()
    @new.render()

