$(document).ready ->
  # Add BVR placeholder
  $("iframe").contents().find(".a4_page").addClass("with_bvr")

  # timeout alerts
  $(".alert").each ->
    setTimeout((=> $(@).fadeOut()), 2000)
