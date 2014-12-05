$(document).ready ->

  Ui.load_tabs $(document)
  Ui.load_ui $(document)

  enable_popover = ->
    $("table.table tr.danger, table.table tr.warning").popover()

  $("table.table").on "datatable_redraw", ->
    enable_popover()

  enable_popover() # onload

  # collect selected lines
  # console.log $('#settings_products_import table').dataTable().fnSettings()

  $('#settings_products_import').on 'submit', (e) ->
    form = $(e.target)
    $(form.find("table").dataTable().fnGetNodes()).find("input[type='checkbox']:checked").map (index, c) ->
      line = $(c).parents("tr").data("line")
      i = $("<input>")
        .attr('type', 'hidden')
        .attr('name', 'lines[]')
        .val( line )
      form.append i
