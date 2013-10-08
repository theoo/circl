$(document).ready ->

  # load app
  admin = new Admin()

  # import people
  people = $('#import')
  if people.length > 0
    people.dataTable
      bJQueryUI: true
      sScrollX: '100%'
      sPaginationType: 'full_numbers'
      bFilter: false

  # finally load ui
  Ui.load_tabs $(document)
  Ui.load_ui $(document)
