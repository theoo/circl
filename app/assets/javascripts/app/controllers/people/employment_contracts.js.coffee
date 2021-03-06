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

PersonEmploymentContract = App.PersonEmploymentContract

$.fn.employment_contract = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonEmploymentContract.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  render: =>
    @employment_contract = new PersonEmploymentContract
    @html @view('people/employment_contracts/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @employment_contract.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name="employment-contract-destroy"]': 'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonEmploymentContract.exists(@id)
    @employment_contract = PersonEmploymentContract.find(@id)
    @show()
    @html @view('people/employment_contracts/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @employment_contract.fromForm(e.target)

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications @employment_contract
      @hide()

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    PersonEmploymentContract.bind('refresh', @render)

  render: =>
    @html @view('people/employment_contracts/index')(@)

  edit: (e) ->
    employment_contract = $(e.target).employment_contract()
    @activate_in_list(e.target)
    @trigger 'edit', employment_contract.id

  table_redraw: =>
    if @affair
      target = $(@el).find("tr[data-id=#{@affair.id}]")

    @activate_in_list(target)

class App.PersonEmploymentContracts extends Spine.Controller
  className: 'employment_contracts'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonEmploymentContract.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/employment_contracts"

    @index = new Index
    @edit = new Edit
    @new = new New(person_id: @person_id)
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active(id: id)
      @edit.render_errors errors

  activate: ->
    super
    PersonEmploymentContract.fetch()
    @new.render()
