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
    'available-permission-add': 'add'

  constructor: (params) ->
    super
    Permission.bind('refresh', @render)
    RolePermission.bind('refresh', @render)

  render: =>
    has_permission = (p) ->
      _.find RolePermission.all(), (rp) ->
        p.action == rp.action && p.subject == rp.subject

    @available_permissions = _.reject(Permission.all(), has_permission)

    @html @view('settings/roles/permissions/available_permissions')(@)
    Ui.load_ui(@el)

  add: (e) ->
    available_permission = $(e.target).available_permission()
    attributes = available_permission.attributes()
    delete attributes.id

    permission = new RolePermission(attributes)
    @save_with_notifications permission

class SelectedPermissionsIndex extends App.ExtendedController
  events:
    'role-permission-edit': 'edit'
    'role-permission-destroy': 'destroy'

  constructor: (params) ->
    super
    RolePermission.bind('refresh', @render)

  render: =>
    @html @view('settings/roles/permissions/selected_permissions')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    Ui.spin_on @el
    permission = $(e.target).selected_permission()

    RolePermission.one 'refresh', =>
      Ui.spin_off @el
      @trigger('edit', {role_id: permission.role_id, id: permission.id})

    RolePermission.fetch(id: permission.id)

  destroy: (e) ->
    permission = $(e.target).selected_permission()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications permission

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @el.dialog(title: I18n.t('role.view.edit_permissions'))
    @el.dialog('open')
    @render()

  render: =>
    return unless RolePermission.exists(@id)
    @permission = RolePermission.find(@id)
    @html @view('settings/roles/permissions/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @permission.fromForm(e.target), =>
      @el.dialog('close')

class App.SettingsRolePermissions extends Spine.Controller
  className: 'role_permissions'

  constructor: (params) ->
    super

    RolePermission.url = =>
      "#{Spine.Model.host}/settings/roles/#{params.role_id}/permissions"

    # flush data and remove container when closing window
    @el.dialog
      close: (event, ui) ->
        RolePermission.refresh([], clear: true)

    container = Ui.stack_window('edit-permission-window', {width: 700, remove_on_close: false})
    @edit = new Edit(el: container)

    @selected_permissions_index = new SelectedPermissionsIndex
    @available_permissions_index = new AvailablePermissionsIndex
    @append(@available_permissions_index, @selected_permissions_index)

    @selected_permissions_index.bind 'edit', (params) =>
      @edit.active(params)

  activate: (params) ->
    RolePermission.fetch()
