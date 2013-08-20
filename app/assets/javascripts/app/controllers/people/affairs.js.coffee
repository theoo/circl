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
Person = App.Person
PersonAffair = App.PersonAffair

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
    @affair = new PersonAffair
    @affair.owner_id = @affair.buyer_id = @affair.receiver_id = @person.id
    @affair.owner_name = @affair.buyer_name = @affair.receiver_name = @person.name
    @html @view('people/affairs/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @affair.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonAffair.exists(@id)
    @show()
    @affair = PersonAffair.find(@id)
    @html @view('people/affairs/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @affair.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'affair-edit': 'edit'
    'affair-edit-prestations': 'edit_prestations'
    'affair-edit-invoices-and-receipts': 'edit_invoices_and_receipts'
    'affair-show-owner': 'show_owner'
    'affair-destroy': 'destroy'

  constructor: (params) ->
    super
    @person_id = params.person_id
    PersonAffair.bind('refresh', @render)

  render: =>
    @html @view('people/affairs/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    affair = $(e.target).affair()
    @trigger 'edit', affair.id

  edit_prestations: (e) ->
    affair = $(e.target).affair()

    on_close = ->
      # Remove obsoletes events
      App.Subscription.unbind('refresh')
      App.PersonAffairSubscription.unbind('refresh')

    window = Ui.stack_window('edit-prestations-window', {width: 800, remove_on_close: true, remove_callback: on_close})
    controller = new App.PersonAffairPrestations({el: window, person_id: @person_id, affair_id: affair.id})
    $(window).dialog({title: I18n.t('affair.view.edit_prestations')})
    $(window).dialog('open')
    controller.activate()

  edit_invoices_and_receipts: (e) ->
    affair = $(e.target).affair()

    # TODO: Remove obsoletes events
    # on_close = ->
    #  # Remove obsoletes events
    #  App.Subscription.unbind('refresh')
    #  App.PersonAffairSubscription.unbind('refresh')

    window = Ui.stack_window('edit-invoices-and-receipts-window', {width: 1200, remove_on_close: true})
    controller = new App.PersonAffairInvoicesAndReceipts({el: window, person_id: @person_id, affair_id: affair.id})
    $(window).dialog({title: I18n.t('affair.view.edit_invoices_and_receipts')})
    $(window).dialog('open')
    controller.activate()

  show_owner: (e) ->
    affair = $(e.target).affair()
    window.location = "/people/#{affair.owner_id}?folding=person_affairs"

  destroy: (e) ->
    affair = $(e.target).affair()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications(affair)

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

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    Person.fetch(id: @person_id)
    PersonAffair.fetch()
    @new.render()
