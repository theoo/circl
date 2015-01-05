class App.TagCloud extends App.ExtendedController
  constructor: (params) ->
    super
    # TODO Reselect tags when loading. Require query parsing
    # @json_query = $('#directory_json_query').val()
    # @query = $.parseJSON(@json_query)

  activate: ->
    super
    # Cannot use spine events with jquery-ui selectable
    update_private_tags_id = (e) =>
      @private_tags_ids = @extract_ids(e)
      @update_query_form()

    @el.find('ol.private_tags').selectable
      selected: update_private_tags_id
      unselected: update_private_tags_id

    update_public_tags_id = (e) =>
      @public_tags_ids = @extract_ids(e)
      @update_query_form()

    @el.find('ol.public_tags').selectable
      selected: update_public_tags_id
      unselected: update_public_tags_id

  private_tags_ids: []
  public_tags_ids: []

  extract_ids: (e) =>
    e.preventDefault()
    $.map($(e.target).find(".ui-selected a"), (val, i) -> $(val).data('id'))

  update_query_form: =>
    tags = []
    tags.push "private_tags.id:("+ @private_tags_ids.join(" ") + ")" if @private_tags_ids.length > 0
    tags.push "public_tags.id:("+ @public_tags_ids.join(" ") + ")" if @public_tags_ids.length > 0
    query = tags.join(" OR ")
    $("#search_string").val(query)

