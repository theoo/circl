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
AffairsCondition = App.AffairsCondition

$.fn.affair_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  elementID

# Modules
ConditionsController =
  update_conditions: (e) ->
    e.preventDefault()
    id = $(e.target).val()
    textarea = @el.find('#affair_conditions')

    if AffairsCondition.exists(id)
      condition = AffairsCondition.find(id)
      textarea.val(condition.description)
    else
      textarea.val("")

StakeholdersController =
  remove_value_item: (e) ->
    current_row = $(e.target).closest("tr")
    current_row.remove()

  add_value_item: (e) ->
    item_template = @el.find('tr[data-name="stakeholder_item_template"]')
    new_row = item_template.clone()
    # theses attributes belongs to template only
    new_row.removeAttr('data-name')
    new_row.removeAttr('style')
    # this class make it selected on submit
    new_row.addClass('item')

    value_item_add = @el.find('tr[data-name="stakeholder_item_add"]')
    value_item_add.before(new_row)

    Ui.load_ui(new_row)

  fetch_items: (e) ->
    values = []
    @el.find('table.table tr.item').each (i, tr) ->
      tr = $(tr)
      val =
        id: tr.find("input[name='stakeholders[][id]']").prop('value')
        title: tr.find("input[name='stakeholders[][title]']").prop('value')
        person_id: tr.find("input[name='stakeholders[][person_id]']").prop('value')

      values.push val

    return values

LocalUi =
  update_badge: ->
    PersonAffair.one 'count_fetched', ->
      $('a[href=#affairs_tab] .badge').html PersonAffair.count()
    PersonAffair.fetch_count()

class New extends App.ExtendedController

  @include ConditionsController
  @include StakeholdersController
  @include LocalUi

  events:
    'submit form': 'submit'
    'change select[name="condition_id"]': 'update_conditions'
    'click button[name="remove_item"]': 'remove_value_item'
    'click button[name="add_item"]': 'add_value_item'

  constructor: (params) ->
    super
    @person_id = params.person_id if params.person_id
    Person.bind('refresh', @render)
    @template = {}

  active: (params) =>
    @person = Person.find(@person_id) if Person.exists(@person_id)

    if params
      if params.parent_id
        @parent_id = params.parent_id

        if params.type == 'copy'
          # create a new child based on its parent's data
          # parent_id is the current Affair which is clicked, already local
          parent = PersonAffair.find(@parent_id)
          @template =
            owner_id:             parent.owner_id
            owner_name:           parent.owner_name
            buyer_id:             parent.buyer_id
            buyer_name:           parent.buyer_name
            receiver_id:          parent.receiver_id
            receiver_name:        parent.receiver_name
            seller_id:            parent.seller_id
            seller_name:          parent.seller_name
            title:                I18n.t("affair.views.variant_prefix") +  ": " + parent.title
            description:          parent.description
            value_in_cents:       parent.value_in_cents
            value_currency:       parent.currency
            estimate:             parent.estimate?
            unbillable:           parent.unbillable?
            parent_id:            parent.id
            parent_title:         parent.title
            footer:               parent.footer
            conditions:           parent.conditions
            condition_id:         parent.condition_id
            affairs_stakeholders: parent.affairs_stakeholders

          @render()
          # Lock the parent field so user cannot change it by mistake
          @el.find("input[name='parent']").button(disabled: true)

    else
      @template =
        affairs_stakeholders: []
        unbillable: false
        seller_id: App.current_user.id
        seller_name: App.current_user.name

      @template.owner_id = @template.buyer_id = @template.receiver_id = @person.id
      @template.owner_name = @template.buyer_name = @template.receiver_name = @person.name

      @render()

  render: =>
    @affair = new PersonAffair(@template)
    @html @view('people/affairs/form')(@)

  submit: (e) =>
    e.preventDefault()

    redirect_to_edit = (id) =>
      @trigger('edit', id)
      @update_badge()

    data = $(e.target).serializeObject()
    @affair.load(data)
    @affair.affairs_stakeholders = @fetch_items()
    @affair.value_currency = App.ApplicationSetting.value("default_currency") unless @affair.value_currency
    @affair.estimate = data.estimate?
    @affair.unbillable = data.unbillable?
    @affair.custom_value_with_taxes = data.custom_value_with_taxes?
    @save_with_notifications @affair, redirect_to_edit

class Edit extends App.ExtendedController

  @include ConditionsController
  @include StakeholdersController
  @include LocalUi

  events:
    'submit form': 'submit'
    'click button[name="cancel"]': 'cancel'
    'click button[name="affair-show-owner"]': 'show_owner'
    'click a[name="affair-destroy"]': 'destroy'
    'click a[name="affair-copy"]': 'copy'
    'click button[name=reset_value]': 'reset_value'
    'click a[name="affair-preview-pdf"]': 'preview'
    'click a[name="affair-download-pdf"]': 'pdf'
    'click a[name="affair-download-odt"]': 'odt'
    'change select[name="condition_id"]': 'update_conditions'
    'click button[name="remove_item"]': 'remove_value_item'
    'click button[name="add_item"]': 'add_value_item'

  constructor: ->
    super
    @balance = new Balance
    PersonAffair.bind('refresh', @render)

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

    # tooltips
    @el.find("a[href=#person_affair_tasks]").tooltip
      placement: 'bottom'
      title: @affair.tasks_duration_translation

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @affair.load(data)
    @affair.affairs_stakeholders = @fetch_items()
    @affair.estimate = data.estimate?
    @affair.unbillable = data.unbillable?
    @affair.custom_value_with_taxes = data.custom_value_with_taxes?
    @save_with_notifications @affair

  cancel: (e) ->
    e.preventDefault()
    @unload_dependencies()
    super(e)

  show_owner: (e) ->
    window.location = "/people/#{@affair.owner_id}#affairs"

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @unload_dependencies()
      @destroy_with_notifications @affair, (id) =>
        @hide()
        @update_badge()

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

  copy: (e) ->
    e.preventDefault()
    @trigger 'copy', {parent_id: @id, type: 'copy'}


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

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).affair_id()

    if $(e.target).parent("tr").hasClass("info")
      # Foreign affair
      App.Affair.one 'refresh', =>
        @affair = App.Affair.find(id)
        window.location = "/people/" + @affair.owner_id + "#affairs"

      App.Affair.fetch(id: id)

    else
      # Normal affair
      PersonAffair.one 'refresh', =>
        @affair = PersonAffair.find(id)
        @activate_in_list(e.target)
        @trigger 'edit', @affair.id

      PersonAffair.fetch(id: id)

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

    @render()

  deactive: (params) =>
    # TODO
    @render()

  render: =>
    @html @view('people/affairs/balance')(@)

    # TODO Improve display
    if @affair_id and PersonAffair.exists(@affair_id)
      @affair = PersonAffair.find(@affair_id)
      rawData = [
        [@affair.value_with_taxes, 2],
        [@affair.invoices_value_with_taxes, 1],
        [@affair.receipts_value, 0]
      ]

      dataSet = [{ label: false, data: rawData, color: "#000" }]
      ticks = [
        [2, I18n.t("person.views.affairs")],
        [1, I18n.t("affair.views.invoices")],
        [0, I18n.t("affair.views.receipts")]
      ]

      options =
        series:
            stack: true
            bars:
              show: true
        bars:
          barWidth: 0.8
          align: 'center'
          horizontal: true
          lineWidth: 1
        xaxis:
            color: "black"
        yaxis:
            axisLabel: false
            ticks: ticks
            color: "black"
        grid:
          hoverable: true
          borderWidth: 0
          borderColor: null

      progress = @el.find(".progress")
      $.plot(progress, dataSet, options);

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

    @edit.bind 'copy', (params) =>
      @new.active(params)
      @edit.hide()

    @index.bind 'edit', (id) =>
      @edit.active(id: id, person_id: @person_id)

    # TODO, if an error is raised the record is unloaded

    @edit.bind 'destroyError', (id, errors) =>
      PersonAffair.one 'refresh', =>
        @edit.active id: id
        @edit.render_errors errors
      PersonAffair.fetch(id: id)

  activate: ->
    super

    AffairsCondition.one 'refresh', =>
      PersonAffair.fetch()
      @new.active()

    AffairsCondition.fetch()
