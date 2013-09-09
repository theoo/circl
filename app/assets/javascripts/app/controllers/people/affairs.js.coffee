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

Person = App.Person
PersonAffair = App.PersonAffair
PersonAffairSubscription = App.PersonAffairSubscription
# PersonAffairTask = App.PersonAffairTask
# PersonAffairProduct = App.PersonAffairProduct
# PersonAffairExtra = App.PersonAffairExtra

$.fn.affair = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonAffair.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    @person_id = params.person_id if params.person_id
    Person.bind('refresh', @render)
    super

  render: =>
    return unless Person.exists(@person_id)
    @person = Person.find(@person_id)
    @affair = new PersonAffair()
    @affair.owner_id = @affair.buyer_id = @affair.receiver_id = @person.id
    @affair.owner_name = @affair.buyer_name = @affair.receiver_name = @person.name
    @html @view('people/affairs/form')(@)
    Ui.load_ui(@el)

  submit: (e) =>
    e.preventDefault()

    redirect_to_edit = (id) =>
      @trigger('edit', id)

    @save_with_notifications @affair.fromForm(e.target), redirect_to_edit

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name="affair-edit-prestations"]': 'edit_prestations'
    'click button[name="affair-edit-invoices-and-receipts"]': 'edit_invoices_and_receipts'
    'click button[name="affair-show-owner"]': 'show_owner'
    'click button[name="affair-destroy"]': 'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @person_id = params.person_id if params.person_id
    @load_dependencies()
    @render()

  load_dependencies: ->
    # Subscriptions
    PersonAffairSubscription.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/subscriptions"
    PersonAffairSubscription.refresh([], clear: true)
    PersonAffairSubscription.fetch()

    # Tasks

    # Products

    # Extras

  unload_dependencies: ->
    PersonAffairSubscription.url = => undefined
    PersonAffairSubscription.refresh([], clear: true)

  render: =>
    return unless PersonAffair.exists(@id)
    @show()
    @affair = PersonAffair.find(@id)
    @html @view('people/affairs/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @affair.fromForm(e.target), @hide
    @unload_dependencies()

  show_owner: (e) ->
    window.location = "/people/#{@affair.owner_id}?folding=person_affairs"

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @affair, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    @person_id = params.person_id
    PersonAffair.bind('refresh', @render)

  active: (params) ->
    if params
      @person_id = params.person_id
      @affair = PersonAffair.find(params.affair_id)
    @render()

  render: =>
    @html @view('people/affairs/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    affair = $(e.target).affair()
    @activate_in_list(e.target)
    @trigger 'edit', affair.id

  table_redraw: =>
    if @affair
      target = $(@el).find("tr[data-id=#{@affair.id}]")

    @activate_in_list(target)

class App.PersonAffairs extends Spine.Controller
  className: 'affairs'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonAffair.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/affairs"

    @index = new Index(person_id: @person_id)
    @edit = new Edit
    @new = new New(person_id: @person_id)
    @append(@new, @edit, @index)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', =>
      @new.render()
      @new.show()

    @new.bind 'edit', (id) =>
      @edit.active(id: id, person_id: @person_id)
      @index.active(affair_id: id, person_id: @person_id)

    @index.bind 'edit', (id) =>
      @edit.active(id: id, person_id: @person_id)

    @index.bind 'destroyError', (id, errors) =>
      @edit.render_errors errors

  activate: ->
    super
    Person.fetch(id: @person_id)
    PersonAffair.fetch()
    @new.render()
