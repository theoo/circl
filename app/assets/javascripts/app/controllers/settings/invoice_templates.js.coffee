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
InvoiceTemplate = App.InvoiceTemplate
Language = App.Language

$.fn.invoice_template = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  InvoiceTemplate.find(elementID)

class InvoiceTemplateController extends App.ExtendedController
  toggle_bvr: (e) ->

    elems = [ $(@el).find("textarea[name='bvr_address']"),
              $(@el).find("input[name='bvr_account']") ]

    if $(e.target).attr('checked')
      # enable bvr
      for el in elems
        el.attr('disabled', false)
      @add_bvr_if_needed()

    else
      # disable bvr
      for el in elems
        el.attr('disabled', true)
      @remove_bvr()

  add_bvr_if_needed: ->
    page = $(@el).find('iframe')
                 .contents()
                 .find('.a4_page')
    page.append(@partial('bvr')(@)) if page.find('.bvr').length == 0

  remove_bvr: ->
    $(@el).find('iframe')
          .contents()
          .find('.bvr').remove()

  toggle_placeholders: ->
    $("#invoice_template_placeholders_list").toggle('fold')

class New extends InvoiceTemplateController
  events:
    'submit form':                        'submit'
    'click #invoice_template_with_bvr':   "toggle_bvr"
    'click #invoice_template_placeholder_button':   "toggle_placeholders"

  constructor: ->
    super
    get_callback = (data) =>
      @placeholders = data
    $.get(InvoiceTemplate.url() + "/placeholders", get_callback, 'json')

  active: ->
    @render()

  render: =>
    if @placeholders
      @invoice_template = new InvoiceTemplate(placeholders: @placeholders)
      @invoice_template.html = @view('settings/invoice_templates/template')(@)
      @invoice_template.with_bvr = true
      @invoice_template.show_invoice_value = true
      @html @view('settings/invoice_templates/form')(@)
      Ui.load_ui(@el)
      $(@el).dialog('open')

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @invoice_template.load(data)
    @invoice_template.with_bvr = data.with_bvr?
    @invoice_template.show_invoice_value = data.show_invoice_value?
    @save_with_notifications @invoice_template, @close

class Edit extends InvoiceTemplateController
  events:
    'submit form':                        'submit'
    'click #invoice_template_with_bvr':   "toggle_bvr"
    'keyup textarea[name="bvr_address"]': "update_bvr"
    'keyup input[name="bvr_account"]':    "update_bvr"
    'click #invoice_template_placeholder_button':   "toggle_placeholders"

  constructor: ->
    super
    Language.bind 'refresh', @render

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless InvoiceTemplate.exists(@id)
    @show()
    @invoice_template = InvoiceTemplate.find(@id)
    @html @view('settings/invoice_templates/form')(@)
    Ui.load_ui(@el)
    fake_e = new $.Event("click")
    fake_e.target = $("#invoice_template_with_bvr")
    @toggle_bvr(fake_e)
    @open()

  submit: (e) =>
    e.preventDefault()
    data = $(e.target).serializeObject()
    @invoice_template.load(data)
    @invoice_template.with_bvr = data.with_bvr?
    @invoice_template.show_invoice_value = data.show_invoice_value?
    @save_with_notifications @invoice_template, @close

class Index extends App.ExtendedController
  events:
    'invoice_template-edit':      'edit'
    'invoice_template-destroy':   'destroy'
    'click input[type="submit"]': 'new'

  constructor: (params) ->
    super
    InvoiceTemplate.bind('refresh', @render)
    Language.bind('refresh', @unlock_new)

  render: =>
    @html @view('settings/invoice_templates/index')(@)
    Ui.load_ui(@el)
    @unlock_new() if @new_unlocked

  new: (e) ->
    @trigger 'new'

  unlock_new: (e) =>
    @el.find('input[type="submit"]').button('enable')
    @new_unlocked = true

  edit: (e) ->
    invoice_template = $(e.target).invoice_template()
    @trigger 'edit', invoice_template.id

  destroy: (e) ->
    invoice_template = $(e.target).invoice_template()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications invoice_template

class App.SettingsInvoiceTemplates extends Spine.Controller
  className: 'invoice_templates'

  constructor: (params) ->
    super

    @edit_template_window = Ui.stack_window('edit-invoice-template-window', {width: 1000, position: 'top', remove_on_close: false})
    $(@edit_template_window).dialog({title: I18n.t('invoice_template.views.edit_template')})

    @new_template_window = Ui.stack_window('new-invoice-template-window', {width: 1000, position: 'top', remove_on_close: false})
    $(@new_template_window).dialog({title: I18n.t('invoice_template.views.new_template')})

    @index = new Index
    @edit = new Edit({el: @edit_template_window})
    @new = new New({el: @new_template_window})

    @append(@index)

    @index.bind 'edit', (id) => @edit.active(id: id)
    @index.bind 'new', => @new.active()

    @index.bind 'destroyError', (id, errors) =>
      @index.renderErrors errors

  activate: ->
    super
    Language.fetch()
    InvoiceTemplate.fetch()
