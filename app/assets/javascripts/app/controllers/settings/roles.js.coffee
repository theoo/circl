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

# .role method is used by jQuery Ui and may conflict
$.fn.get_role = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Role.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @role = new Role()
    @html @view('settings/roles/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @role.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless Role.exists(@id)
    @show()
    @role = Role.find(@id)
    @html @view('settings/roles/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @role.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'role-edit':      'edit'
    'role-destroy':   'destroy'
    'role-members':   'view_members'
    'permissions-edit': 'edit_permissions'

  constructor: (params) ->
    super
    Role.bind('refresh', @render)

  render: =>
    @html @view('settings/roles/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    role = $(e.target).get_role()
    @trigger 'edit', role.id

  destroy: (e) ->
    role = $(e.target).get_role()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications role

  view_members: (e) ->
    role = $(e.target).get_role()
    App.search_query(search_string: "roles.id:#{role.id}")

  edit_permissions: (e) ->
    role = $(e.target).get_role()

    container_id = 'edit-permissions-window'

    Ui.stack_window(container_id, {width: 1200, remove_on_close: true})
    @permissions_controller = new App.SettingsRolePermissions({role_id: role.id, el: '#' + container_id})
    $('#' + container_id).modal({title: "#{I18n.t('role.view.edit_permissions_for_role')} '#{role.name}'"})
    $('#' + container_id).modal('show')
    @permissions_controller.activate()

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

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    Role.fetch()
    Permission.refresh([], clear: true) # needed because we don't return ids for all permissions
    Permission.fetch() # required when loading role's permissions
    @new.render()
