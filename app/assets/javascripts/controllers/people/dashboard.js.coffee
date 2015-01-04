$(document).ready ->

  dashboard = new Dashboard({id: $('#person_id').val()})

  Ui.lazy_affix_list()

  # finally load ui
  Ui.load_ui $(document)
  Ui.toggle_affix_menu("dashboard_affix")
