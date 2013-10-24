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

Subscription = App.Subscription
InvoiceTemplate = App.InvoiceTemplate

$.fn.admin_subscription_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  elementID

class ValueItemsController extends App.ExtendedController

  remove_value_item: (e) ->
    current_row = $(e.target).closest("tr")
    current_row.remove()

  add_value_item: (e) ->
    item_template = @el.find('tr[data-name="value_item_template"]')
    new_row = item_template.clone()
    # theses attributes belongs to template only
    new_row.removeAttr('data-name')
    new_row.removeAttr('style')
    # this class make it selected on submit
    new_row.addClass('item')

    value_item_add = @el.find('tr[data-name="value_item_add"]')
    value_item_add.before(new_row)

    Ui.load_ui(new_row)

  make_table_sortable: (e) ->
    sortableTableHelper = (e, ui) ->
      ui.children().each ->
        $(@).width($(@).width());
      return ui

    @el.find('table.category').sortable(
        items: "tr.item"
        handle: '.handle'
        placeholder: 'placeholder'
        helper: sortableTableHelper
        axis: 'y'
        stop: (event,ui) =>
          @apply_positions()
          @make_item_removable()
    )

    @make_item_removable()

  make_item_removable: (e) ->
    @el.find('table.category tr.item').each ->
      $(@).find('td:last input[type="button"]').show()

    # hide the first remove button
    @el.find('table.category tr.item:first td:last input[type="button"]').hide()

  apply_positions: ->
    @el.find('tr.item').each (index,tr) ->
      tr = $(tr)
      position = tr.find("input[name='values[][position]']")
      position.attr('value', index)

  fetch_items: (e) ->
    @apply_positions()

    values = []
    @el.find('table.table tr.item').each (i, tr) ->
      tr = $(tr)
      val =
        id: tr.find("input[name='values[][id]']").prop('value')
        value: tr.find("input[name='values[][value]']").prop('value')
        position: tr.find("input[name='values[][position]']").prop('value')
        private_tag_id: tr.find("input[name='values[][private_tag_id]']").prop('value')
        invoice_template_id: tr.find("select[name='values[][invoice_template_id]'] option:selected").prop('value')

      values.push val

    return values

class New extends ValueItemsController
  events:
    'submit form':                      'submit'
    'click button[name="remove_item"]':  'remove_value_item'
    'click button[name="add_item"]':     'add_value_item'

  constructor: (params) ->
    super
    InvoiceTemplate.bind('refresh', @render)

    @template = { values: [{value: 0}] }

  active: (params) ->
    if params
      if params.parent_id
        @parent_id = params.parent_id
        @status = params.type

        switch params.type
          when 'reminder'
            Subscription.one 'refresh', =>
              # create a new child based on its parent's data
              parent = Subscription.find(@parent_id)
              @template =
                parent_title: parent.title
                parent_id:    parent.id
                title:        I18n.t("subscription.views.reminder") +  ": " + parent.title
                values:       parent.values
                description:  parent.description
                invoice_template_id: parent.invoice_template_id
                interval_starts_on:  parent.interval_starts_on
                interval_ends_on:    parent.interval_ends_on

              @render()
              # Lock the parent field so user cannot change it by mistake
              @el.find("input[name='subscription_parent_title']").button(disabled: true)

          when 'renewal'
            Subscription.one 'refresh', =>
              parent = Subscription.find(@parent_id)

              if parent.interval_starts_on
                # create a new child based on its parent's data
                # Compute the new date in accord to the former interval
                from = parent.interval_starts_on.to_date()
                to = parent.interval_ends_on.to_date()
                new_from = new Date(to.getFullYear(), to.getMonth(), to.getDate()+1)
                new_to = new Date(new_from.getTime() + (to - from))

              @template =
                # parent_title: parent.title # parent title is hidden
                parent_id:    parent.id # parent will be removed after renewal
                title:        I18n.t("subscription.views.renewal") +  ": " + parent.title
                values:       parent.values
                description:  parent.description
                invoice_template_id: parent.invoice_template_id
                interval_starts_on:  new_from.to_view() if new_from
                interval_ends_on:    new_to.to_view() if new_to

              @render()
              # Lock the parent field so user cannot add one by mistake
              @el.find("input[name='subscription_parent_title']").button(disabled: true)

        Subscription.fetch(id: @parent_id)
    else
      # @template is cleared, render it to wipe previous @template if existing
      @render()

  render: =>
    # build a new subscription with the template, if existing
    @subscription = new Subscription(@template)

    @html @view('admin/subscriptions/form')(@)

    # append an empty value as a placeholder to add one
    # unless it's a reminder
    @add_value_item() unless @subscription.values.length > 0

    # allow user to sort and redefine position
    @make_table_sortable()


  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()
    attr.values = @fetch_items()
    @subscription = new Subscription(attr)
    @subscription.status = @status
    @save_with_notifications @subscription, @render

class Edit extends ValueItemsController
  events:
    'submit form': 'submit'
    'click button[name="remove_item"]':  'remove_value_item'
    'click button[name="add_item"]':     'add_value_item'
    'click button[name=subscription-destroy]':                'destroy'
    'click a[name=subscription-pdf]':                         'pdf'
    'click a[name=subscription-members-view]':                'view_members'
    'click a[name=subscription-buyers-view]':                 'view_buyers'
    'click a[name=subscription-receivers-view]':              'view_receivers'
    'click a[name=subscription-members-who-paid-view]':       'view_members_who_paid'
    'click a[name=subscription-members-who-didnt-paid-view]': 'view_members_who_didnt_paid'
    'click a[name=subscription-members-add]':                 'add_members'
    'click a[name=subscription-members-remove]':              'remove_members'
    'click a[name=subscription-transfer-overpaid-value]':     'transfer_overpaid_value'
    'click a[name=subscription-reminder]':                    'create_reminder'
    'click a[name=subscription-renewal]':                     'renew'

  constructor: ->
    super
    InvoiceTemplate.bind('refresh', @render)

  active: (params) ->
    @id = params.id if params.id
    @subscription = Subscription.find(@id)
    @render()

  render: =>
    return unless Subscription.exists(@id)
    @show()
    @html @view('admin/subscriptions/form')(@)

    # This should not happen
    @add_value_item() unless @subscription.values.length > 0

    # allow user to sort and redefine position
    @make_table_sortable()


  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()
    attr.values = @fetch_items()

    # Allow to remove parent
    attr.parent_id = undefined if attr.subscription_parent_title == ""

    @save_with_notifications @subscription.load(attr), @hide

  pdf: (e) ->
    e.preventDefault()

    query       = new App.QueryPreset
    url         = "#{Subscription.url()}/#{@subscription.id}.pdf"
    title       = I18n.t('subscription.views.sort_people_for_pdf_generation_of') + " <i>" + @subscription.title + "</i>"
    message     = I18n.t('subscription.views.sort_people_message')

    Directory.search_with_custom_action query,
      url: url
      title: title
      message: message

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      Subscription.one 'refresh', =>
        @destroy_with_notifications @subscription

  view_members: (e) ->
    e.preventDefault()
    Directory.search(search_string: "subscriptions.id:#{@id}")

  view_buyers: (e) ->
    e.preventDefault()
    Directory.search(search_string: "subscriptions_as_buyer.id:#{@id}")

  view_receivers: (e) ->
    e.preventDefault()
    Directory.search(search_string: "subscriptions_as_receiver.id:#{@id}")

  view_members_who_paid: (e) ->
    e.preventDefault()
    Directory.search(search_string: "paid_subscriptions.id:#{@id}")

  view_members_who_didnt_paid: (e) ->
    e.preventDefault()
    Directory.search(search_string: "unpaid_subscriptions.id:#{@id}")

  add_members: (e) ->
    e.preventDefault()

    query       = new App.QueryPreset
    url         = "#{Subscription.url()}/#{@subscription.id}/add_members"
    title       = I18n.t('subscription.views.add_members_title') + " <i>" + @subscription.title + "</i>"
    message     = I18n.t('subscription.views.add_members_message')

    Directory.search_with_custom_action query,
      url: url
      title: title
      message: message

  remove_members: (e) ->
    e.preventDefault()

    if confirm(I18n.t('common.are_you_sure'))
      settings =
        url: "#{Subscription.url()}/#{@id}/remove_members"
        type: 'DELETE',

      ajax_error = (xhr, statusText, error) =>
        @render_errors $.parseJSON(xhr.responseText)

      ajax_success = (data, textStatus, jqXHR) =>
        Subscription.fetch(id: @id)

      Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)

  transfer_overpaid_value: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='subscription-transfert-overpaid-value-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new TransferOverpaidValue({el: win.find('.modal-content'), subscription: @subscription})
    win.modal('show')
    controller.activate()

  create_reminder: (e) ->
    e.preventDefault()
    @trigger 'new', {parent_id: @id, type: 'reminder'}

  renew: (e) ->
    e.preventDefault()
    @trigger 'new', {parent_id: @id, type: 'renewal'}

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'click button[name=subscription-tag-tool]':  'tag_tool'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    Subscription.bind('refresh', @render)

  render: =>
    @html @view('admin/subscriptions/index')(@)

  edit: (e) ->
    e.preventDefault()

    id = $(e.target).admin_subscription_id()
    Subscription.one 'refresh', =>
      @subscription = Subscription.find(id)
      @activate_in_list(e.target)
      @trigger 'edit', @subscription.id

    Subscription.fetch(id: id)

  tag_tool: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salaries-tag-tool-modal' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    controller = new TagTool({el: win.find('.modal-content')})
    win.modal('show')
    controller.activate()

  table_redraw: =>
    if @subscription
      target = $(@el).find("tr[data-id=#{@subscription.id}]")
    @activate_in_list(target)

class TransferOverpaidValue extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    @subscription = params.subscription
    @render()

  render: =>
    @html @view("admin/subscriptions/transfer_overpaid")(@)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    settings =
      url: "#{Subscription.url()}/#{@subscription.id}/transfer_overpaid_value"
      type: 'POST',
      data: JSON.stringify(attr)

    ajax_error = (xhr, statusText, error) =>
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      $(@el).modal('hide')
      Subscription.fetch()

    Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)

class TagTool extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  activate: ->
    @render()

  render: =>
    @html @view('admin/subscriptions/tag')(@)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()

    settings =
      url: "#{Subscription.url()}/tag_tool",
      type: 'PUT',
      data: JSON.stringify(attr)

    ajax_error = (xhr, statusText, error) =>
      @enable_panel()
      @render_errors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      @enable_panel()
      App.PrivateTag.fetch({id: attr.private_tag_id})
      $(@el).modal('hide')

    Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)
    @disable_panel()

class App.AdminSubscriptions extends Spine.Controller
  className: 'subscriptions'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', =>
      @new.active()
      @new.show()

    @edit.bind 'new', (params) =>
      @new.active(params)
      @edit.hide()

    @index.bind 'edit', (id) =>
      @edit.active(id: id)
      @new.hide()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    InvoiceTemplate.fetch()
    InvoiceTemplate.one 'refresh', =>
      # No need to fetch, datatable is remote and loaded by Ui.js
      @index.render()
