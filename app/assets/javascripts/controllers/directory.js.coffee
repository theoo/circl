$(document).ready ->

  # testing markers instead of container because to page may return and empty array of markers
  if $("[name=map_markers]").length > 0
    Ui.load_map('map_container')

  if $('#directory_json_query').length > 0
    directory = new Directory

  Ui.load_tabs $(document)
  Ui.load_ui $(document)

  # Import people report, add popover on errors
  $("table.table tr.danger").popover()
