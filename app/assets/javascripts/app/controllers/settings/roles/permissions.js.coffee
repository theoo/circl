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

RolePermission = App.RolePermission
Permission = App.Permission

$.fn.available_permission = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Permission.find(elementID)

$.fn.selected_permission = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  RolePermission.find(elementID)

class AvailablePermissionsIndex extends App.ExtendedController
  events:
    'click tr.item': 'add'

  constructor: (params) ->
    super
    Permission.bind('refresh', @render)
    RolePermission.bind('refresh', @render)

  active: (params) ->
    @role_id = params.role_id if params

  render: =>
    has_permission = (p) ->
      _.find RolePermission.all(), (rp) ->
        p.action == rp.action && p.subject == rp.subject

    @available_permissions = _.reject(Permission.all(), has_permission)

    @html @view('settings/roles/permissions/available_permissions')(@)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    RolePermission.url() == undefined

  add: (e) =>
    available_permission = $(e.target).available_permission()
    attributes = available_permission.attributes()
    delete attributes.id

    permission = new RolePermission(attributes)
    @save_with_notifications permission, =>
      App.Role.fetch(id: @role_id)

class SelectedPermissionsIndex extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'click button[name=role-permission-destroy]': 'destroy'

  constructor: (params) ->
    super
    RolePermission.bind('refresh', @render)

  active: (params) ->
    @role_id = params.role_id if params

  render: =>
    @html @view('settings/roles/permissions/selected_permissions')(@)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    RolePermission.url() == undefined

  edit: (e) ->
    permission = $(e.target).selected_permission()

    RolePermission.one 'refresh', =>
      @trigger 'edit', permission.id

    RolePermission.fetch(id: permission.id)

  destroy: (e) =>
    permission = $(e.target).selected_permission()
    @destroy_with_notifications permission, =>
      App.Role.fetch(id: @role_id)

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super
    RolePermission.bind 'refresh', @render

  active: (params) ->
    @id = params.id if params
    @render()

  render: =>
    if RolePermission.exists(@id)
      @permission = RolePermission.find(@id)
    else
      @permission = new RolePermission

    @html @view('settings/roles/permissions/form')(@)
    if @permission.isNew()
      $("#settings_role_permission_action").prop("disabled", true)
      $("#settings_role_permission_subject").prop("disabled", true)
      $("#settings_role_permission_hash_conditions").prop("disabled", true)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    RolePermission.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @permission.fromForm(e.target), =>
      @active(id: undefined)

class App.SettingsRolePermissions extends Spine.Controller
  className: 'role_permissions'

  constructor: (params) ->
    super
    @edit = new Edit
    @available_permissions_index = new AvailablePermissionsIndex
    @selected_permissions_index = new SelectedPermissionsIndex


    @append @available_permissions_index, $("<hr />"), @edit, @selected_permissions_index

    @selected_permissions_index.render()
    @available_permissions_index.render()

    @selected_permissions_index.bind 'edit', (id) =>
      @edit.active(id: id)

  activate: (params) ->
    if params
      @edit.active(params.id) # undefined is ok

      if params.role_id
        @available_permissions_index.active(role_id: params.role_id)
        @selected_permissions_index.active(role_id: params.role_id)
