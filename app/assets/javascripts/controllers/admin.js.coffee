$(document).ready ->

  # load app
  admin = new Admin()

  # finally load ui
  Ui.load_tabs $(document)
  Ui.load_ui $(document)
