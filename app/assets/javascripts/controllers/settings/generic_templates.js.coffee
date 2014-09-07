$(document).ready ->
  # timeout alerts
  $(".alert").each ->
    setTimeout((=> $(@).fadeOut()), 2000)
