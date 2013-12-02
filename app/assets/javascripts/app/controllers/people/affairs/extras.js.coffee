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

PersonAffairExtra = App.PersonAffairExtra

$.fn.extra = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) =>
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id
      @can = params.can if params.can

    @render()

  render: =>
    @show()
    @extra = new PersonAffairExtra(quantity: 1)
    @html @view('people/affairs/extras/form')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairExtra.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @extra.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name=person-affair-extra-destroy]': 'destroy'

  constructor: ->
    super

  active: (params) =>
    @can = params.can if params.can
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonAffairExtra.exists(@id) && @can
    @extra = PersonAffairExtra.find(@id)

    @html @view('people/affairs/extras/form')(@)
    @show()
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairExtra.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @extra.fromForm(e.target), @hide

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @extra, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=extras-csv]': 'export_csv'
    'click a[name=extras-pdf]': 'export_pdf'

  constructor: (params) ->
    super
    PersonAffairExtra.bind('refresh', @render)

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    @html @view('people/affairs/extras/index')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairExtra.url() == undefined

  edit: (e) ->
    @id = $(e.target).extra()
    @activate_in_list e.target
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

  export_csv: (e) ->
    e.preventDefault()
    window.location = PersonAffairExtra.url() + ".csv"

  export_pdf: (e) ->
    e.preventDefault()
    window.location = PersonAffairExtra.url() + ".pdf"

class App.PersonAffairExtras extends Spine.Controller
  className: 'extras'

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

  activate: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    App.Permissions.get { person_id: @person_id, can: { extra: ['create', 'update'] }}, (data) =>
      @new.active { person_id: @person_id, affair_id: @affair_id, can: data }
      @index.active {can: data}
      @edit.active {can: data}
      @edit.hide()
