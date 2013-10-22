$(document).ready ->
  # new/edit
  person_edit = new PersonEdit({id: $('#person_id').attr('value')})

  # finally load ui
  Ui.load_tabs $(document)
  Ui.load_ui $(document)
