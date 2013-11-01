$(document).ready ->

  person_edit = new PersonEdit({id: $('#person_id').val()})

  # finally load ui
  Ui.load_tabs $(document)
  Ui.load_ui $(document)
