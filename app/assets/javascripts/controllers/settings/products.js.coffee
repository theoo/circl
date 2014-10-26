$(document).ready ->

  Ui.load_tabs $(document)
  Ui.load_ui $(document)

  enable_popover = ->
    $("table.table tr.danger, table.table tr.warning").popover()

  $("table.table").on "datatable_redraw", ->
    enable_popover()

  enable_popover() # onload