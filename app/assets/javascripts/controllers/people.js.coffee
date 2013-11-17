$(document).ready ->

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

