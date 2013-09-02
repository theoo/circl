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

    # this token may be usefull for certain ajax calls
    @authenticity_token = $('meta[name="csrf-token"]').attr('content');

  # inline
  hide: =>
    $(@el).hide()
    @trigger 'hide'

  show: =>
    $(@el).show()
    @trigger 'show'

  # stacked windows
  open: =>
    $(@el).modal('show')
    @trigger 'open'

  close: =>
    $(@el).modal('hide')
    @trigger 'close'

  reset_notifications: ->
    # remove previous errors
    $(@el).find('.has-error').each (index, field_with_error) ->
      $(field_with_error).removeClass('has-error')
      $(field_with_error).popover('destroy')

  render_errors: (errors) ->
    @reset_notifications()

    # Set panel as 'danger' bootstrap class
    panel = $(@el).closest('.panel')
    panel.removeClass 'panel-primary panel-default'
    panel.addClass 'panel-danger'

    # render error partial
    # TODO remove useless partial 'error_messages_for.js.hamlc'
    # el.find('.validation_errors_placeholder').html(@partial('error_messages_for')(errors: errors))

    # point fields with errors
    for attr, msg of errors
      field_with_error = $(@el).find("[name='#{attr}']")
      unless first_field
        first_field = field_with_error

      unless field_with_error.length > 0
        field_with_error = $(@el).find("[name='#{attr}_id']")

      field_with_error = field_with_error.parent()

      # Add some red
      field_with_error.addClass('has-error')

      # Add error explanation
      field_with_error.popover
        # container: 'body' # This is recommended in bootstrap doc but will break reset_notifications
        content: msg
        trigger: 'manual'
        placement: 'auto bottom'
      field_with_error.popover('show')

    # Focus first error field
    first_field.focus()


  render_success: ->
    @reset_notifications()

    # Set panel as 'success' bootstrap class
    panel = $(@el).closest('.panel')
    panel.removeClass 'panel-primary panel-default panel-danger'
    panel.addClass 'panel-success'

    restore_panel_status = ->
      original_class = if panel.data('primary_panel') then 'panel-primary' else 'panel-default'

      # jQuery UI transition, only working on borders
      panel.switchClass 'panel-success', original_class, {duration: 3000, easing: 'easeInOutCubic'}
      # TODO Make transition work on panel-heading sub-class too

    setTimeout(restore_panel_status, 1000)


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

  save_with_notifications: (record, success) ->
    is_new = record.isNew()

    # TODO Don't know why this lies here, ajax_prepare catch ajaxError which should be enough
    # Validation errors
    # record.bind 'error', (unused, message) =>
    #   record.unbind(@)
    #   @render_errors message.errors

    # Ajax
    @ajax_prepare(record, success)

    record.save()

  destroy_with_notifications: (record, success) ->
    # Ui
    ui_error = =>
      # TODO Notify
      # Ui.notify @el, I18n.t('common.failed_to_destroy'), 'error'
    ui_success = =>
      # TODO Notify
      # Ui.notify @el, I18n.t('common.successfully_destroyed'), 'notice'

    # Ajax
    ajax_error = (xhr, statusText, error) =>
      record.constructor.refresh record.attributes()
      @trigger 'destroyError', record.id, $.parseJSON(xhr.responseText)

    ajax_success = (xhr, statusText, error) =>
      record.destroy(ajax: false)
      record.constructor.trigger 'refresh'
      success() if success

    # TODO we could avoid the manual ajax request by binding after destroy, see https://github.com/maccman/spine/issues/327
    # (tho maybe it's better to wait for the spine refactoring which would return promises objects)
    record.ajax().ajax(type: 'DELETE', url: record.url())
      .error(ui_error).success(ui_success)
      .error(ajax_error).success(ajax_success)

  get_url_parameter: (name) ->
    decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [null,""])[1].replace(/\+/g, '%20')) || null

  # validations
  validate_date_format: (date) =>
    Ui.validate_date_format(date)
