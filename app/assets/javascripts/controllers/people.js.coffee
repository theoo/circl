$(document).ready ->
  # show/edit
  person_id = $('#person_id').attr('value')
  if person_id
    person_edit = new PersonEdit({id: person_id})

  # finally load ui
  Ui.load_ui $(document)

  # Tabs
  rewrite_url_anchor = (anchor_name) ->
    url = window.location.hash
    params = url.match(/(\?.*)$/)
    params = if params then params[0] else ""
    window.location.hash = anchor_name + params
    # window.location.hash = anchor_name + params
    # TODO prevent browser from scrolling to anchor, it may exist a better solution.
    @.scrollTo(0,0)

  $("#sub_nav a").click (e) ->
    e.preventDefault()
    $(@).tab('show')

  $("#sub_nav a").on 'shown.bs.tab', (e) ->
    rewrite_url_anchor $(e.target).attr('href')

  anchor = window.location.hash.match(/^(#[a-z]+)\??/)
  anchor = anchor[1] if anchor

  tab_link = $("#sub_nav a[href=" + anchor + "]")
  tab_link = $("#sub_nav a[href=#info]") if tab_link.length == 0
  tab_link.tab('show')
