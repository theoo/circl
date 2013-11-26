$(document).ready ->

  # action map
  if $("#map_container").length > 0
    id = $('#person_id').val()
    ph = $(".validation_errors_placeholder")
    save_callback = (latlng) ->
      settings =
        url: "#{App.Person.url()}/#{id}",
        type: 'PUT',
        data:
          person:
            latitude: latlng.lat,
            longitude: latlng.lng

      ajax_error = (xhr, statusText, error) =>
        ph.removeClass "alert-success"
        ph.addClass "alert alert-danger"
        ph.html I18n.t("common.errors.failed_to_update")

      ajax_success = (data, textStatus, jqXHR) =>
        ph.removeClass "alert-danger"
        ph.addClass "alert alert-success"
        ph.html I18n.t("common.notices.successfully_updated")

      $.ajax(settings).error(ajax_error).success(ajax_success)

    Ui.load_map('map_container', save_callback)

  # action edit
  if $('#info_tab').length > 0
    person_edit = new PersonEdit({id: $('#person_id').val()})

    # add anchor to pagination so the tab remains the same.
    on_tab_change_callback = ->
      $("#pagination a").each (index, el) ->
        anchor = location.hash.split('#')
        if anchor
          url = $(el).attr('href').split("#")[0]
          $(el).attr('href', [url, anchor[1]].join("#"))

    # finally load ui
    Ui.load_tabs $(document), on_tab_change_callback
    Ui.load_ui $(document)
