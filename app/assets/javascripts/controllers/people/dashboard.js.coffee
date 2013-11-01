$(document).ready ->

  dashboard = new Dashboard({id: $('#person_id').val()})

  # finally load ui
  Ui.load_ui $(document)
