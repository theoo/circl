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

# error object used in model validations
class App.ErrorsList
  constructor: ->
    @clear()

  add: (hash) ->
    for attr, message of hash
      @errors[attr] ||= []
      @errors[attr].push(message)

  is_empty: ->
    Object.keys(@errors).length == 0

  clear: ->
    @errors = {}

# template to handle error objects
class App.ExtendedController extends Spine.Controller

  constructor: ->
    super

  html: ->
    super
    Ui.load_ui(@el)

  # inline
  hide: =>
    $(@el).hide()
    @trigger 'hide'

  show: =>
    $(@el).show()
    @trigger 'show'

  cancel: (e) ->
    e.preventDefault()
    @el.parent().find("tr[data-id=#{$(e.target).attr('data-id')}]").removeClass('active')
    @hide()

  reset: (e) ->
    e.preventDefault()
    @el.find("input").val("")
    @el.find("textarea").val("")
    @active()

  # stacked windows
  reset_notifications: ->
    # remove previous errors
    $(@el).find('.has-error').each (index, field_with_error) ->
      $(field_with_error).find('input, textarea, checkbox, select').popover('destroy')
      $(field_with_error).removeClass('has-error')

  render_errors: (errors) ->
    @reset_notifications()

    # Set panel as 'danger' bootstrap class
    panel = $(@el).closest('.panel')
    panel.removeClass 'panel-primary panel-default'
    panel.addClass 'panel-danger'

    # Object to store errors which doesn't belongs to an input field (general errors)
    general_errors = {}

    # point fields with errors
    for attr, msg of errors
      field_with_error = $(@el).find("[name='#{attr}']")

      # Autocompleters
      # If attr ends with "_id" and field_with_error is hidden, use sibling text field instead
      if attr.match(/_id$/) and field_with_error.attr('type') == 'hidden'
        related_attr = attr.match(/^(.*)_id$/)[1]
        field_with_error = $(@el).find("[name='#{related_attr}']")

      unless first_field
        first_field = field_with_error

      unless field_with_error.length > 0
        field_with_error = $(@el).find("[name='#{attr}_id']")

      # If no fields are found, push it in general_errors Object
      unless field_with_error.length > 0
        general_errors[attr] = msg

      # Add some red
      field_with_error.parent().addClass('has-error')

      # Add error explanation
      field_with_error.popover
        # This is recommended in bootstrap doc but will break reset_notifications
        # container: 'body'
        # Popover is bound strait to the corresponding field and it seams to work fine.
        content: msg
        trigger: 'manual'
        placement: 'auto bottom'
      field_with_error.popover('show')

      field_with_error.siblings(".popover").on 'click', ->
        # Yes, it's a strange way to select field_with_error, but field_with_error itself
        # returns the last field with error instead of the current one.
        $(@).closest('.has-error').find('input, textarea, checkbox, select').popover("hide")

    # Print general errors:
    # In the rare case where errors are raised on base, display a global alert in validation placeholder.
    $(@el)
      .find('.validation_errors_placeholder')
      .html(@partial('error_messages_for')(errors: general_errors))

    # Focus first error field
    first_field.focus()

  render_success: ->
    @reset_notifications()

    # Set panel as 'success' bootstrap class
    panel = $(@el).closest('.panel')
    panel.removeClass 'panel-primary panel-default panel-danger'
    panel.addClass 'panel-success'
    panel.find("button[type=submit]").effect("highlight", color: "#d6e9c6")

    restore_panel_status = ->
      original_class = if panel.data('primary_panel') then 'panel-primary' else 'panel-default'

      # jQuery UI transition, only working on borders
      panel.switchClass 'panel-success', original_class, {duration: 3000, easing: 'easeInOutCubic'}
      # TODO Make transition work on panel-heading sub-class too

    setTimeout(restore_panel_status, 3000)

  original_attributes: (record) ->
    current = record.dup()
    current.id = record.id
    current.reload().attributes()

  ajax_prepare_error_for_create: (record) ->
    record.bind 'ajaxError', (unused, xhr, statusText, error) =>
      # On error, destroy the record that was inserted by Spine
      record.unbind(@)
      record.destroy ajax: false
      @render_errors $.parseJSON(xhr.responseText)

  ajax_prepare_error_for_update: (record) ->
    attributes = @original_attributes(record)
    record.bind 'ajaxError', (unused, xhr, statusText, error) =>
      # On error, restore the original attribute in the collection
      record.unbind(@)
      record.constructor.refresh attributes
      @render_errors $.parseJSON(xhr.responseText)

  ajax_prepare: (record, success) ->
    if record.isNew()
      @ajax_prepare_error_for_create(record)
    else
      @ajax_prepare_error_for_update(record)

    record.bind 'ajaxSuccess', (newrecord, data, statusText, xhr) =>
      record.unbind(@)
      obj = {}
      for key in Object.keys(data)
        obj[key] = data[key]
      record.constructor.refresh(obj)
      success(newrecord.id) if success
      @render_success()

  save_with_notifications: (record, success_callback) ->
    is_new = record.isNew()

    # Spine Validation errors
    record.bind 'error', (unused, message) =>
      record.unbind(@)
      @render_errors message.errors

    @ajax_prepare(record, success_callback)

    record.save()

  destroy_with_notifications: (record, success_callback) ->
    # Ui
    ui_error = =>
      # Set panel as 'danger' bootstrap class
      panel = $(@el).closest('.panel')
      panel.removeClass 'panel-primary panel-default panel-success'
      panel.addClass 'panel-danger'

    ui_success = =>
      # Set panel as 'danger' bootstrap class
      panel = $(@el).closest('.panel')
      panel.removeClass 'panel-primary panel-default panel-danger'
      panel.addClass 'panel-success'

    # Ajax
    ajax_error = (xhr, statusText, error) =>
      record.constructor.refresh record.attributes()
      @trigger 'destroyError', record.id, $.parseJSON(xhr.responseText)
      # TODO Perhaps it's possible to remove callbacks and run the generic code here
      # 90% of controllers have the same callback code.

    ajax_success = (xhr, statusText, error) =>
      record.destroy(ajax: false)
      record.constructor.trigger 'refresh'
      success_callback() if success_callback

    # TODO we could avoid the manual ajax request by binding after destroy, see https://github.com/maccman/spine/issues/327
    # (tho maybe it's better to wait for the spine refactoring which would return promises objects)
    record.ajax().ajax(type: 'DELETE', url: record.url())
      .error(ui_error).success(ui_success)
      .error(ajax_error).success(ajax_success)

  get_url_parameter: (name) ->
    decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [null,""])[1].replace(/\+/g, '%20')) || null

  # validations
  validate_date_format: (date_str) =>
    date_str.match(/^[0-3][0-9]-[0-1][0-9]-[0-9]{1,4}$/)

  validate_interval: (from_str, to_str) =>
    # TODO l10n

    localize = (date_str) ->
      a = date_str.match(/^([0-3][0-9])-([0-1][0-9])-([0-9]{1,4})$/)
      a.shift()
      a.reverse().join("-")

    from = Date.parse localize(from_str)
    to = Date.parse localize(to_str)

    from < to

  # UI
  activate_in_list: (target) ->
    # if target is undefined it will clear the list
    if $(target).length > 0
      tr = $(target).closest('tr')

      tr.addClass('active')

      # Save status of current item and remove its class
      for status in ['warning', 'danger', 'success']
        if tr.hasClass(status)
          tr.data('status', status)
          tr.removeClass(status)

      trs = tr.siblings()

    else
      trs = $(@el).find('tr')

    trs.each (index, i) ->
      item = $(i)
      # Restore status of all items
      item.addClass(item.data('status')) if item.data('status')

      item.removeClass('active')

  disable_panel: ->
    $(@el).find("input, select, checkbox, textarea").each (index, i) ->
      $(i).prop('disabled', true)

    $(@el).closest(".panel").addClass 'panel-disabled'

  enable_panel: ->
    $(@el).find("input, select, checkbox, textarea").each (index, i) ->
      $(i).prop('disabled', false)

    $(@el).closest(".panel").removeClass 'panel-disabled'

  # Money - VAT
  setup_vat: (params) =>
    @ids_prefix = params.ids_prefix

    if params.bind_events
      @el.on 'click', "a[name=#{@ids_prefix}adjust-vat]", @adjust_vat
      @el.on 'keyup', "\##{@ids_prefix}value", @adjust_vat
      @el.on 'keyup', "\##{@ids_prefix}vat", @highlight_vat
      @el.on 'keyup', "\##{@ids_prefix}vat_percentage", @highlight_vat

  highlight_vat: (e) =>
    e.preventDefault() if e
    if @compare_vat()
      @el.find("#" + @ids_prefix + 'vat')
        .closest('.form-group')
        .removeClass('has-warning')
    else
      @el.find("#" + @ids_prefix + 'vat')
        .closest('.form-group')
        .addClass('has-warning')

  adjust_vat: (e) =>
    e.preventDefault() if e
    @update_vat()

  compute_vat: () =>
    val = @el.find("#" + @ids_prefix + 'value').val()
    rate = @el.find("#" + @ids_prefix + 'vat_percentage').val()
    parseFloat((parseFloat(val) / 100.0 * parseFloat(rate)).toFixed(2))

  compare_vat: () =>
    vat = @compute_vat()
    parseFloat(@el.find("#" + @ids_prefix + 'vat').val()) == vat

  update_vat: () =>
    vat = @compute_vat()
    vat_field = @el.find("#" + @ids_prefix + 'vat')
    if vat_field.attr('disabled')
      vat_field.val("")
    else
      vat_field.val(vat)
      @highlight_vat()

  # Function called from events, trigger sent from ui.js#bind_currency_selector
  on_currency_change: (e) ->
    e.preventDefault()
    currency_input = $(e.target)
    vat_currency_input = @el.find("input[name=vat_currency]")
    vat_currency_input.val currency_input.val()
    @el.find("##{@ids_prefix}vat_currency").html(currency_input.val())

    @adjust_vat(e)

  # level = [ info | warning | danger ]
  confirm: (msg, level, accept_callback, decline_callback) ->

    win = $("<div class='modal fade modal-#{level}' id='confirm' tabindex='-1' role='dialog' />")

    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.confirm')

    win.find('.modal-header').addClass

    # Insert message
    win.find('.modal-body').html msg

    # Remove original button
    win.find('.modal-footer').html ""

    # Buttons
    cancel = "<button type='button' class='btn btn-default' data-dismiss='modal'>"
    cancel += "<i class='icon-chevron-left' /> "
    cancel += I18n.t('common.cancel')
    cancel += "</button>"
    cancel = $(cancel)
    win.find('.modal-footer').append cancel
    cancel.on 'click', (e) =>
      e.preventDefault()
      decline_callback() if decline_callback
      win.modal('hide')

    destroy = "<button type='button' class='btn btn-danger' data-dismiss='modal'>"
    destroy += I18n.t('common.destroy')
    destroy += " <i class='icon-chevron-right' />"
    destroy += "</button>"
    destroy = $(destroy)
    win.find('.modal-footer').append destroy
    destroy.on 'click', (e) =>
      e.preventDefault()
      accept_callback() if accept_callback
      win.modal('hide')

    if level == 'danger'
      double_check = "<br /><br /><input type='checkbox' name='double-check-confirm' /> "
      double_check += I18n.t("common.double_check_confirm")
      win.find('.modal-body').append double_check

      destroy.attr 'disabled', true

      win.delegate "input[name='double-check-confirm']", 'click', (e) ->
        destroy.attr 'disabled', $("input[name='double-check-confirm']:checked").length == 0

    win.modal('show')
