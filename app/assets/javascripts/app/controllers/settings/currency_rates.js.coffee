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

CurrencyRate = App.CurrencyRate

$.fn.currency_rate = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @show()
    @currency_rate = new CurrencyRate(archive: false)
    @html @view('settings/currency_rates/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @currency_rate.load(data)
    @save_with_notifications @currency_rate, @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name="cancel"]': 'cancel'
    'click a[name=settings-currency-rate-destroy]': 'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    CurrencyRate.one 'refresh', =>
      @currency_rate = CurrencyRate.find(@id)
      @render()
    CurrencyRate.fetch id: @id

  render: =>
    @show()
    @html @view('settings/currency_rates/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @currency_rate.load(data)
    @save_with_notifications @currency_rate

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @currency_rate, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    CurrencyRate.bind('refresh', @render)

  render: =>
    @html @view('settings/currency_rates/index')(@)

  edit: (e) ->
    @id = $(e.target).currency_rate()
    @activate_in_list e.target
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

class App.SettingsCurrencyRates extends Spine.Controller
  className: 'currency_rates'

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
      @edit.render_errors errors

  activate: ->
    super
    CurrencyRate.fetch()
    @new.render()
