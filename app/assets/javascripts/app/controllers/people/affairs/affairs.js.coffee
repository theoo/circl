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
PersonTask = App.PersonTask
PersonAffairProductsProgram = App.PersonAffairProductsProgram
PersonAffairExtra = App.PersonAffairExtra
PersonAffairInvoice = App.PersonAffairInvoice
PersonAffairReceipt = App.PersonAffairReceipt

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

  active: (params) =>
    @render()

  render: =>
    return unless Person.exists(@person_id)
    @person = Person.find(@person_id)
    @affair = new PersonAffair(conditions: App.ApplicationSetting.value("default_affair_conditions"))
    @affair.owner_id = @affair.buyer_id = @affair.receiver_id = @person.id
    @affair.owner_name = @affair.buyer_name = @affair.receiver_name = @person.name

    @current_user = App.current_user
    @affair.seller_id = @current_user.id
    @affair.seller_name = @current_user.name

    @html @view('people/affairs/form')(@)

  submit: (e) =>
    e.preventDefault()

    redirect_to_edit = (id) =>
      @trigger('edit', id)
      # Update badge
      $('a[href=#affairs_tab] .badge').html PersonAffair.count()

    data = $(e.target).serializeObject()
    @affair.load(data)
    @affair.value_currency = App.ApplicationSetting.value("default_currency") unless @affair.value_currency
    @affair.custom_value_with_taxes = data.custom_value_with_taxes?
    @save_with_notifications @affair, redirect_to_edit

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name="affair-show-owner"]': 'show_owner'
    'click a[name="affair-destroy"]': 'destroy'
    'click button[name=reset_value]': 'reset_value'
    'click a[name="affair-preview-pdf"]': 'preview'
    'click a[name="affair-download-pdf"]': 'pdf'
    'click a[name="affair-download-odt"]': 'odt'

  constructor: ->
    super
    @balance = new Balance

  active: (params) ->
    @id = params.id if params.id
    @person_id = params.person_id if params.person_id
    @load_dependencies()
    @render()

  load_dependencies: ->
    if @id
      # Subscriptions
      PersonAffairSubscription.url = =>
        "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/subscriptions"
      PersonAffairSubscription.refresh([], clear: true)
      PersonAffairSubscription.fetch()

      # Tasks
      # person_affairs, which is @el of App.PersonAffairs
      person_affair_tasks_ctrl = $("#person_affair_tasks").data('controller')
      person_affair_tasks_ctrl.activate(person_id: @person_id, affair_id: @id)
      PersonTask.url = =>
        "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/tasks"
      PersonTask.refresh([], clear: true)
      PersonTask.fetch()

      # # Products
      person_affair_products_ctrl = $("#person_affair_products").data('controller')
      person_affair_products_ctrl.activate(person_id: @person_id, affair_id: @id)
      PersonAffairProductsProgram.url = =>
        "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/products"
      PersonAffairProductsProgram.refresh([], clear: true)
      PersonAffairProductsProgram.fetch()

      # Extras
      person_affair_extras_ctrl = $("#person_affair_extras").data('controller')
      person_affair_extras_ctrl.activate(person_id: @person_id, affair_id: @id)
      PersonAffairExtra.url = =>
        "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/extras"
      PersonAffairExtra.refresh([], clear: true)
      PersonAffairExtra.fetch()

      @balance.active(affair_id: @id)

      # Invoices
      # #person_affairs, which is @el of App.PersonAffairs
      person_affair_invoices_ctrl = $("#person_affair_invoices").data('controller')
      person_affair_invoices_ctrl.activate(person_id: @person_id, affair_id: @id)
      PersonAffairInvoice.url = =>
        "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/invoices"
      PersonAffairInvoice.refresh([], clear: true)
      PersonAffairInvoice.fetch()

      # Receipts
      person_affair_receipts_ctrl = $("#person_affair_receipts").data('controller')
      person_affair_receipts_ctrl.activate(person_id: @person_id, affair_id: @id)
      PersonAffairReceipt.url = =>
        "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@id}/receipts"
      PersonAffairReceipt.refresh([], clear: true)
      PersonAffairReceipt.fetch()

  unload_dependencies: ->
    # Subscriptions
    PersonAffairSubscription.url = => undefined
    PersonAffairSubscription.refresh([], clear: true)

    # Tasks
    PersonTask.url = => undefined
    PersonTask.refresh([], clear: true)

    # Products
    PersonAffairProductsProgram.url = => undefined
    PersonAffairProductsProgram.refresh([], clear: true)

    # Extras
    PersonAffairExtra.url = => undefined
    PersonAffairExtra.refresh([], clear: true)

    @balance.deactive()

    # Invoices
    PersonAffairInvoice.url = => undefined
    PersonAffairInvoice.refresh([], clear: true)

    # Receipts
    PersonAffairReceipt.url = => undefined
    PersonAffairReceipt.refresh([], clear: true)

  render: =>
    return unless PersonAffair.exists(@id)
    @show()
    @affair = PersonAffair.find(@id)
    @html @view('people/affairs/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @affair.load(data)
    @affair.custom_value_with_taxes = data.custom_value_with_taxes?
    @save_with_notifications @affair, (id) =>
      @hide()
      @unload_dependencies()

  show_owner: (e) ->
    window.location = "/people/#{@affair.owner_id}#affairs"

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @unload_dependencies()
      @destroy_with_notifications @affair, (id) =>
        @hide()
        # Update badge
        $('a[href=#affairs_tab] .badge').html PersonAffair.count()

  reset_value: (e) ->
    e.preventDefault()
    @el.find("#person_affair_value").val @affair.computed_value

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_template").val()
    window.location = "#{PersonAffair.url()}/#{@affair.id}.pdf?template_id=#{@template_id}"

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_template").val()
    window.location = "#{PersonAffair.url()}/#{@affair.id}.odt?template_id=#{@template_id}"

  preview: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_template").val()

    win = $("<div class='modal fade' id='affair-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.preview') + ": " + @affair.title

    # Insert iframe to content
    iframe = $("<iframe src='" +
                "#{PersonAffair.url()}/#{@affair.id}.html?template_id=#{@template_id}" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    win.find('.modal-body').html iframe

    # Adapt width to A4
    win.find('.modal-dialog').css(width: 900)

    # Add preview in new tab button
    btn = "<button type='button' name='affair-preview-in-new-tab' class='btn btn-default'>"
    btn += I18n.t('affair.views.actions.preview_in_new_tab')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonAffair.url()}/#{@affair.id}.html?template_id=#{@template_id}", "affair_preview"

    win.modal('show')


class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=people-affairs-documents-affairs]':  'documents_affairs'
    'click a[name=people-affairs-documents-invoices]': 'documents_invoices'
    'click a[name=people-affairs-documents-receipts]': 'documents_receipts'

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
    @el.find("tr.warning").popover()

  edit: (e) ->
    e.preventDefault()
    @affair = $(e.target).affair()
    @activate_in_list(e.target)
    @trigger 'edit', @affair.id

  table_redraw: =>
    if @affair
      target = $(@el).find("tr[data-id=#{@affair.id}]")

    @activate_in_list(target)

  documents_affairs: (e) ->
    e.preventDefault()
    @documents_machine('affairs')

  documents_invoices: (e) ->
    e.preventDefault()
    @documents_machine('invoices')

  documents_receipts: (e) ->
    e.preventDefault()
    @documents_machine('receipts')

  documents_machine: (content) ->
    win = $("<div class='modal fade' id='affairs-pdf-export-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new DocumentsMachine({el: win.find('.modal-content'), content: content})
    win.modal('show')
    controller.activate()

class Balance extends App.ExtendedController
  constructor: (params) ->
    super
    @el = $("#balance")
    PersonAffair.bind 'refresh', @active

  active: (params) =>
    if params
      @affair_id = params.affair_id if params.affair_id

    if @affair_id and PersonAffair.exists(@affair_id)
      @affair = PersonAffair.find(@affair_id)

      # Compute balance
      if @affair.invoices_value_with_taxes >= @affair.receipts_value
        @overpaid = false
        @paid = 100 / @affair.invoices_value_with_taxes * @affair.receipts_value
      else
        @overpaid = true
        @paid = 100 / @affair.receipts_value * @affair.invoices_value_with_taxes

    @render()

  deactive: (params) =>
    # TODO
    @render()

  render: =>
    @html @view('people/affairs/balance')(@)

class DocumentsMachine extends App.ExtendedController
  events:
    'submit form': 'validate'
    'change #person_affairs_document_export_format': 'format_changed'

  constructor: (params) ->
    super
    @content = params.content

  activate: (params)->
    @format = 'pdf' # default format
    @form_url = App.PersonAffair.url() + "/" + @content

    switch @content
      when 'affairs'
        @template_class = 'Affair'
        App.Affair.fetch_statuses()
        App.Affair.one 'statuses_fetched', =>
          @render()

      when 'invoices'
        @template_class = 'Invoice'
        App.Invoice.fetch_statuses()
        App.Invoice.one 'statuses_fetched', =>
          @render()

      when 'receipts'
        @template_class = 'Receipt'
        @render()

  render: =>
    @html @view('people/affairs/documents')(@)

    switch @content
      when 'affairs'
        @el.find("#person_affairs_document_export_threshold_value_global").attr(disabled: true)
        @el.find("#person_affairs_document_export_threshold_overpaid_global").attr(disabled: true)

  validate: (e) ->
    errors = new App.ErrorsList

    if @el.find("#person_affairs_document_export_format").val() != 'csv'
      unless @el.find("#person_affairs_document_export_template").val()
        errors.add ['generic_template_id', I18n.t("activerecord.errors.messages.blank")].to_property()

    if errors.is_empty()
      # @render_success() # do nothing...
    else
      e.preventDefault()
      @render_errors(errors.errors)

  format_changed: (e) ->
    @format = $(e.target).val()
    @el.find("form").attr('action', @form_url + "." + @format)

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

    # TODO, if an error is raised the record is unloaded

    @edit.bind 'destroyError', (id, errors) =>
      PersonAffair.one 'refresh', =>
        @edit.render_errors errors
      PersonAffair.fetch(id: id)

  activate: ->
    super
    PersonAffair.fetch()
    @new.active()
