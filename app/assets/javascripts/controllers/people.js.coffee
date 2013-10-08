$(document).ready ->
  # show/edit
  person_id = $('#person_id').attr('value')
  if person_id
    person_edit = new PersonEdit({id: person_id})

  # finally load ui
  Ui.load_tabs $(document)
  Ui.load_ui $(document)
