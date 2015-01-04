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

    [map, markers] = Ui.load_map('map_container', save_callback)

    # Override geographic location update form
    $('form').on 'submit', (e) =>
      e.preventDefault()
      geo = $("#person_geographic_coordinates").val().split(",")

      # update hidden input
      markers_input = $("input[name=map_markers]")
      new_marker = JSON.parse(markers_input.val())
      new_marker[0].latlng = geo
      markers_input.val JSON.stringify(new_marker)

      # reload marker
      markers[0].setLatLng(geo)

      # fake latlng object
      latlng = { lat: geo[0], lng: geo[1] }

      # save
      save_callback(latlng)

  # action edit
  if $('#info_tab').length > 0
    person_edit = new PersonEdit({id: $('#person_id').val()})

  # finally load ui
  Ui.initialize_ui()
  Ui.load_ui $(document)
