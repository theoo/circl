$(document).ready ->

  # testing markers instead of container because to page may return and empty array of markers
  if $("[name=map_markers]").length > 0
    $('html').height("100%")
    Ui.load_map('map_container')

  if $('#directory_json_query').length > 0
    directory = new Directory

  Ui.load_tabs $(document)
  Ui.load_ui $(document)

  enable_popover = ->
    $("table.table tr.danger, table.table tr.warning").popover()

  $("table.table").on "datatable_redraw", ->
    enable_popover()

  enable_popover() # onload
