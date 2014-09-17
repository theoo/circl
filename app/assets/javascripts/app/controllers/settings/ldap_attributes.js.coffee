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

LdapAttribute = App.LdapAttribute

$.fn.ldap_attribute = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  LdapAttribute.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="reset"]': 'reset'

  constructor: ->
    super

  render: =>
    @ldap_attribute = new LdapAttribute()
    @html @view('settings/ldap_attributes/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @ldap_attribute.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=settings-ldap-attribute-destroy]': 'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @ldap_attribute = LdapAttribute.find(@id)
    @render()

  render: =>
    @html @view('settings/ldap_attributes/form')(@)
    @show()

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @ldap_attribute.fromForm(e.target)

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @ldap_attribute, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    LdapAttribute.bind('refresh', @render)

  render: =>
    @html @view('settings/ldap_attributes/index')(@)

  edit: (e) ->
    ldap_attribute = $(e.target).ldap_attribute()
    @activate_in_list(e.target)
    @trigger 'edit', ldap_attribute.id

  table_redraw: =>
    if @ldap_attribute
      target = $(@el).find("tr[data-id=#{@ldap_attribute.id}]")

    @activate_in_list(target)

class App.SettingsLdapAttributes extends Spine.Controller
  className: 'ldap_attributes'

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

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    LdapAttribute.fetch()
    @new.render()
