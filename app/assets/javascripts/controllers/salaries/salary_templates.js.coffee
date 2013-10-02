$(document).ready ->
  Ui.load_wysiwyg $(document)
  # timeout alerts
  $(".alert").each ->
    setTimeout((=> $(@).fadeOut()), 2000)
