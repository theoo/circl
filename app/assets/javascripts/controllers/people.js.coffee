$(document).ready ->

  map_container = $("#person_map_container")

  # if existing
  if map_container.length > 0
    map_height = document.height - 210
    map_height = 300 if map_height < 300

    map_container.css(height: map_height)

    latitude = $("[name=person_latitude]").val()
    longitude = $("[name=person_longitude]").val()
    markers = $.parseJSON $("[name=person_map_markers]").val()
    config = $.parseJSON $("[name=person_map_config]").val()

    map = L.map('person_map_container')
    map.setView([latitude, longitude], config.max_zoom)
    $(markers).each ->
      marker = L.marker(@.latlng).addTo(map)
      marker.bindPopup(@.popup)
    L.tileLayer(config.tile_url, {attribution: config.attribution, maxZoom: config.max_zoom }).addTo(map)

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
