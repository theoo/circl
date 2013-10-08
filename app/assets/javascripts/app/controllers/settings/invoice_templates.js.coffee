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

InvoiceTemplate = App.InvoiceTemplate
Language = App.Language

$.fn.invoice_template = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  InvoiceTemplate.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form':                        'submit'

  constructor: ->
    super

  active: ->
    @render()

  render: =>
    @invoice_template = new InvoiceTemplate
    @invoice_template.html = @view('settings/invoice_templates/template')(@)
    @invoice_template.with_bvr = true
    @invoice_template.show_invoice_value = true
    @html @view('settings/invoice_templates/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @invoice_template.load(data)
    @invoice_template.with_bvr = data.with_bvr?
    @invoice_template.show_invoice_value = data.show_invoice_value?
    @save_with_notifications @invoice_template, @close

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name=settings-invoice-template-destroy]': 'destroy'
    'click button[name=settings-invoice-template-edit]': 'edit_template'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @invoice_template = InvoiceTemplate.find(@id)
    @render()

  render: =>
    @show()
    @html @view('settings/invoice_templates/form')(@)

  submit: (e) =>
    e.preventDefault()
    data = $(e.target).serializeObject()
    @invoice_template.load(data)
    @invoice_template.with_bvr = data.with_bvr?
    @invoice_template.show_invoice_value = data.show_invoice_value?
    @save_with_notifications @invoice_template, @close

  edit_template: (e) ->
    e.preventDefault()
    window.open "#{InvoiceTemplate.url()}/#{@invoice_template.id}/edit.html", "invoice_template"

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @invoice_template, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    InvoiceTemplate.bind('refresh', @render)
    Language.bind('refresh', @render)

  render: =>
    @html @view('settings/invoice_templates/index')(@)

  new: (e) ->
    @trigger 'new'

  edit: (e) ->
    invoice_template = $(e.target).invoice_template()
    @activate_in_list(e.target)
    @trigger 'edit', invoice_template.id

  table_redraw: =>
    if @invoice_template
      target = $(@el).find("tr[data-id=#{@invoice_template.id}]")

    @activate_in_list(target)

class App.SettingsInvoiceTemplates extends Spine.Controller
  className: 'settings_invoice_templates'

  constructor: (params) ->
    super

    @new = new New
    @edit = new Edit
    @index = new Index

    @append(@new, @edit, @index)

    @new.bind 'edit', (id) =>
      @edit.active(id: id)
    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    Language.one "refresh", =>
      InvoiceTemplate.fetch()
      @new.render()
    Language.fetch()
