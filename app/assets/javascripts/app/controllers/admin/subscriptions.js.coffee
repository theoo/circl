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

$.fn.subscription_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  elementID

$.fn.subscription_value_id = ->
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
    @el.find('table.category tr.item').each (i, tr) ->
      tr = $(tr)
      val =
        id: tr.find("input[name='values[][id]']").attr('value')
        value: tr.find("input[name='values[][value]']").attr('value')
        position: tr.find("input[name='values[][position]']").attr('value')
        private_tag_id: tr.find("input[name='values[][private_tag_id]']").attr('value')
        invoice_template_id: tr.find("select[name='values[][invoice_template_id]'] option:selected").attr('value')

      values.push val

    return values

class New extends ValueItemsController
  events:
    'submit form':                      'submit'
    'click input[name="remove_item"]':  'remove_value_item'
    'click input[name="add_item"]':     'add_value_item'

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

    Ui.load_ui(@el)

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
    'click input[name="remove_item"]':  'remove_value_item'
    'click input[name="add_item"]':     'add_value_item'

  constructor: ->
    super
    InvoiceTemplate.bind('refresh', @render)

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless Subscription.exists(@id)
    @show()
    @subscription = Subscription.find(@id)
    @html @view('admin/subscriptions/form')(@)

    # This should not happen
    @add_value_item() unless @subscription.values.length > 0

    # allow user to sort and redefine position
    @make_table_sortable()

    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()
    attr.values = @fetch_items()
    @save_with_notifications @subscription.load(attr), @hide

class Index extends App.ExtendedController
  events:
    'subscription-edit':                        'edit'
    'subscription-pdf':                         'pdf'
    'subscription-destroy':                     'destroy'
    'subscription-members-view':                'view_members'
    'subscription-buyers-view':                 'view_buyers'
    'subscription-receivers-view':              'view_receivers'
    'subscription-members-who-paid-view':       'view_members_who_paid'
    'subscription-members-who-didnt-paid-view': 'view_members_who_didnt_paid'
    'subscription-members-add':                 'add_members'
    'subscription-members-remove':              'remove_members'
    'subscription-transfer-overpaid-value':     'transfer_overpaid_value'
    'subscription-reminder':                    'create_reminder'
    'subscription-renewal':                     'renew'
    'submit form':                              'stack_tag_tool_window'

  constructor: (params) ->
    super
    Subscription.bind('refresh', @render)

  render: =>
    @html @view('admin/subscriptions/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    id = $(e.target).subscription_id()
    Subscription.one 'refresh', =>
      subscription = Subscription.find(id)
      @trigger 'edit', subscription.id

    Subscription.fetch(id: id)

  pdf: (e) ->
    id = $(e.target).subscription_id()
    Subscription.one 'refresh', =>
      subscription = Subscription.find(id)

      win = Ui.stack_window('filter-subscription-pdf-window', {width: 1200, remove_on_close: true})
      controller = new App.DirectoryQueryPresets(el: win, edit: { text: I18n.t('directory.views.generate_pdf') })
      controller.bind 'edit', (preset) =>
        $(win).modal('hide')
        window.location = "#{Subscription.url()}/#{subscription.id}.pdf?#{preset.to_params()}"
      $(win).modal({title: I18n.t('subscription.edit_export_filter')})
      $(win).modal('show')
      controller.activate()

    Subscription.fetch(id: id)

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      id = $(e.target).subscription_id()
      Subscription.one 'refresh', =>
        subscription = Subscription.find(id)
        @destroy_with_notifications subscription

      Subscription.fetch(id: id)

  view_members: (e) ->
    id = $(e.target).subscription_id()
    App.search_query(search_string: "subscriptions.id:#{id}")

  view_buyers: (e) ->
    id = $(e.target).subscription_id()
    App.search_query(search_string: "subscriptions_as_buyer.id:#{id}")

  view_receivers: (e) ->
    id = $(e.target).subscription_id()
    App.search_query(search_string: "subscriptions_as_receiver.id:#{id}")

  view_members_who_paid: (e) ->
    id = $(e.target).subscription_id()
    App.search_query(search_string: "paid_subscriptions.id:#{id}")

  view_members_who_didnt_paid: (e) ->
    id = $(e.target).subscription_id()
    App.search_query(search_string: "unpaid_subscriptions.id:#{id}")

  add_members: (e) ->
    id = $(e.target).subscription_id()
    Subscription.one 'refresh', =>
      subscription = Subscription.find(id)

      win = Ui.stack_window('filter-subscription-pdf-window', {width: 1200, remove_on_close: true})
      controller = new App.DirectoryQueryPresets(el: win, search: { text: I18n.t('directory.views.add_to_subscription') })
      controller.bind 'search', (preset) =>
        Ui.spin_on controller.search.el

        settings =
          url: "#{Subscription.url()}/#{subscription.id}/add_members"
          type: 'POST',
          data: JSON.stringify(query: preset.query)

        ajax_error = (xhr, statusText, error) =>
          Ui.spin_off controller.search.el
          Ui.notify controller.search.el, I18n.t('common.failed_to_update'), 'error'
          controller.search.renderErrors $.parseJSON(xhr.responseText)

        ajax_success = (data, textStatus, jqXHR) =>
          Ui.spin_off controller.search.el
          Ui.notify controller.search.el, I18n.t('common.successfully_updated'), 'notice'
          $(win).modal('hide')
          window.location = '/admin'

        Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)

      $(win).modal({title: I18n.t('subscription.add_members')})
      $(win).modal('show')
      controller.activate()

    Subscription.fetch(id: id)

  remove_members: (e) ->
    id = $(e.target).subscription_id()
    Ui.spin_on @el

    settings =
      url: "#{Subscription.url()}/#{id}/remove_members"
      type: 'DELETE',

    ajax_error = (xhr, statusText, error) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @renderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'

    Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)
    Subscription.fetch(id: id)

  transfer_overpaid_value: (e) ->
    id = $(e.target).subscription_id()
    Subscription.one 'refresh', =>
      subscription = Subscription.find(id)

      win = Ui.stack_window('subscription-transfer-overpaid-value-window', {width: 500, remove_on_close: true})
      controller = new TransferOverpaidValue(el: win, subscription_id: subscription.id)
      $(win).modal({title: I18n.t('subscription.views.contextmenu.transfer_overpaid_value')})
      $(win).modal('show')
      controller.render()

    Subscription.fetch(id: id)

  create_reminder: (e) ->
    id = $(e.target).subscription_id()
    Subscription.one 'refresh', =>
      subscription = Subscription.find(id)
      @trigger 'new', {parent_id: subscription.id, type: 'reminder'}

    Subscription.fetch(id: id)

  renew: (e) ->
    id = $(e.target).subscription_id()
    Subscription.one 'refresh', =>
      subscription = Subscription.find(id)
      @trigger 'new', {parent_id: subscription.id, type: 'renewal'}

    Subscription.fetch(id: id)

  stack_tag_tool_window: (e) ->
    e.preventDefault()
    win = Ui.stack_window('subscription-tag-tool-window', {width: 500, remove_on_close: true})
    controller = new TagTool(el: win)
    $(win).modal({title: I18n.t('subscription.views.tool_box.tag_tool')})
    $(win).modal('show')
    controller.render()

class TransferOverpaidValue extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  render: =>
    @html @view('admin/subscriptions/transfer_overpaid')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()
    Ui.spin_on @el

    settings =
      url: "#{Subscription.url()}/#{@subscription_id}/transfer_overpaid_value"
      type: 'POST',
      data: JSON.stringify(attr)

    ajax_error = (xhr, statusText, error) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @renderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      $(@el).modal('hide')
      Subscription.fetch()

    Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)

class TagTool extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  render: =>
    @html @view('admin/subscriptions/tag')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    attr = $(e.target).serializeObject()
    Ui.spin_on @el

    settings =
      url: "#{Subscription.url()}/tag_tool"
      type: 'POST',
      data: JSON.stringify(attr)

    ajax_error = (xhr, statusText, error) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.failed_to_update'), 'error'
      @renderErrors $.parseJSON(xhr.responseText)

    ajax_success = (data, textStatus, jqXHR) =>
      Ui.spin_off @el
      Ui.notify @el, I18n.t('common.successfully_updated'), 'notice'
      App.PrivateTag.fetch({id: attr.private_tag_id})
      $(@el).modal('hide')

    Subscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)

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

    @index.bind 'new', (params) =>
      @new.active(params)
      @edit.hide()

    @index.bind 'edit', (id) =>
      @edit.active(id: id)
      @new.hide()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    InvoiceTemplate.fetch()
    @new.render()
    @index.render()
