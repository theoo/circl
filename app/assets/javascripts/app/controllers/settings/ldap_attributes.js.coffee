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
LdapAttribute = App.LdapAttribute

$.fn.ldap_attribute = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  LdapAttribute.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @ldap_attribute = new LdapAttribute()
    @html @view('settings/ldap_attributes/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @ldap_attribute.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless LdapAttribute.exists(@id)
    @show()
    @ldap_attribute = LdapAttribute.find(@id)
    @html @view('settings/ldap_attributes/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @ldap_attribute.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'ldap_attribute-edit':      'edit'
    'ldap_attribute-destroy':   'destroy'

  constructor: (params) ->
    super
    LdapAttribute.bind('refresh', @render)

  render: =>
    @html @view('settings/ldap_attributes/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    ldap_attribute = $(e.target).ldap_attribute()
    @trigger 'edit', ldap_attribute.id

  destroy: (e) ->
    ldap_attribute = $(e.target).ldap_attribute()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications ldap_attribute

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

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    LdapAttribute.fetch()
    @new.render()
