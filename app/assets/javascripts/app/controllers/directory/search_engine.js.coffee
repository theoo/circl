#  CIRCL Directory
#  Copyright (C) 2011 Complex IT sàrl
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

QueryPreset = App.QueryPreset
SearchAttribute = App.SearchAttribute

$.fn.directory_person_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  elementID

$.fn.query_preset = ->
  selected_option = $(@).find(":selected")
  if selected_option.data('id')
    elementID = selected_option.data('id')
    QueryPreset.find(elementID)
  else
    new QueryPreset
      query:
        search_string: ''
        selected_attributes: []
        attributes_order: []

class SearchEngineExtention extends App.ExtendedController

  # TODO Do not annimate already collapsed #presets and #presets_summary

  constructor: ->
    super
    # NOTE You can invoke custom_action from the search engine
    # with the following hidden inputs (* = required for minimal action)
    # custom_action[url] *
    # custom_action[title]
    # custom_action[message]
    @json_query = $('#directory_json_query').val()

    if $('#directory_custom_action_url').length > 0
      @custom_action =
        search_string: $.parseJSON(@json_query).search_string
        url: unescape($('#directory_custom_action_url').val())
        title: unescape($('#directory_custom_action_title').val())
        message: unescape($('#directory_custom_action_message').val())
        disabled: unescape($('#directory_custom_action_disabled').val())

      if @custom_action.disabled
        ary = []
        $.each @custom_action.disabled.split(","), ->
          ary.push @.trim()
        @custom_action.disabled = ary


  toggle_edit: (e) ->
    e.preventDefault()
    $("#presets_summary").collapse("toggle")
    $("#presets").collapse("toggle")

  load_jquery_ui_interactions: ->
    preset = $("#presets")

    # Setup jQuery UI interactions methods
    # TODO try to enlarge the droppable zone to the panel instead of the list

    # If panel-disabled class is set, panel-default is removed.
    # This way, only active panels are sortable
    preset.find(".panel-default .sortable ol")
      .sortable()
      .disableSelection()

    # This way, only active panels are draggable
    preset.find(".panel-primary .draggable .dt_dd_couple")
      .draggable(
        helper: 'clone'
        connectToSortable: '.sortable ol')
      .disableSelection()

    # Add remove and sort buttons to attributes order and selected attributes
    preset.find(".attributes_order li").each (index, el) =>
      @update_attribute_order_button $(el)
      @update_remove_button $(el)

    preset.find(".selected_attributes li").each (index, el) =>
      @update_remove_button $(el)

    # Colorize available attributes depending on their status: selected or orderd
    @update_attribute_statuses()

    attributes_order_drop_callback = (event, ui) =>
      el = ui.draggable

      # Unable to make "accept" option to work. Doing it myself
      if ! el.hasClass('orderable')
        el.remove()
        return true

      # Source: all attributes
      name = el.find('dt').data('name')

      # Continue if current dragged element if its name is set (then it's not in list)
      if name != undefined and name != null
        if preset.find(".attributes_order li[data-name=" + name + "]").length == 0

          preset.find(".attributes_order .placeholder").remove()

          li = $("<li data-order='asc' class='orderable'></li>")
            .text(el.find('dd').text())

          # data-name must be set this way (not .data('name')) or is not searchable in DOM (jQuery caches it)
          li.attr('data-name', name)
          li.insertAfter $(event.target).find('.dt_dd_couple')
          # li is cloned because .dt_dd_couple is double (cloned when dragged)
          li.remove()

          li = $(".attributes_order li[data-name=" + name + "]")
          @update_remove_button li
          @update_attribute_order_button li
          @update_attribute_statuses()

          # Source is all_attributes, then remove dropped element
        el.remove()

    attributes_order_over_callback = (event, ui) =>
      if ! ui.draggable.hasClass('orderable')
        preset.find('.attributes_order').addClass('drop_denied')

    attributes_order_out_callback = (event, ui) =>
      preset.find('.attributes_order').removeClass('drop_denied')

    selected_attributes_drop_callback = (event, ui) =>
      el = ui.draggable

      # Unable to make "accept" option to work. Doing it myself
      if ! el.hasClass('searchable')
        el.remove()
        return true

      # Source: all attributes
      name = el.find('dt').data('name')

      # Continue if current dragged element if its name is set (then it's not in list)
      if name != undefined and name != null
        if preset.find(".selected_attributes li[data-name=" + name + "]").length == 0

          preset.find(".selected_attributes .placeholder").remove()

          li = $("<li class='searchable'></li>")
            .text(el.find('dd').text())

          # data-name must be set this way (not .data('name')) or is not searchable in DOM (jQuery caches it)
          li.attr('data-name', name)
          li.insertAfter $(event.target).find('.dt_dd_couple')
          # li is cloned because .dt_dd_couple is double (cloned when dragged)
          li.remove()

          @update_remove_button preset.find(".selected_attributes li[data-name=" + name + "]")
          @update_attribute_statuses()

          # Source is all_attributes, then remove dropped element
        el.remove()

    selected_attributes_over_callback = (event, ui) =>
      if ! ui.draggable.hasClass('searchable')
        preset.find('.selected_attributes').addClass('drop_denied')

    selected_attributes_out_callback = (event, ui) =>
      preset.find('.selected_attributes').removeClass('drop_denied')

    # Unless the panel is disabled
    if preset.find(".panel-disabled .attributes_order")
      preset.find(".attributes_order .droppable").droppable
        drop: attributes_order_drop_callback
        over: attributes_order_over_callback
        out: attributes_order_out_callback
        deactivate: attributes_order_out_callback
        # accept: '.orderable' # not working, element can be dropped anyways
        tolerence: 'touch'

    # Unless the panel is disabled
    if preset.find(".panel-default .selected_attributes")
      preset.find(".selected_attributes .droppable").droppable
        drop: selected_attributes_drop_callback
        over: selected_attributes_over_callback
        out: selected_attributes_out_callback
        deactivate: selected_attributes_out_callback
        tolerence: 'touch'

  update_remove_button: (li) ->
    if li.find("a.text-danger").size() == 0 and ! li.hasClass('placeholder')
      remove_button = $("<a name='directory-preset-selected-attribute-remove' class='text-danger'>&times;</a>")
      li.append(remove_button)

      li.find("a.text-danger")
        .on('click', @remove_attribute_from_list)

  update_attribute_order_button: (li) ->
    unless li.hasClass('placeholder')
      # Remove former button
      li.find("a.order").remove()

      # And add a new one
      order_button = $("<a class='order'></a>")
      li.prepend(order_button)

      if li.attr('data-order') == 'asc'
        order_button.append("<i class='icon-caret-up'> ")
        order_button.on 'click', (e) =>
          li = $(e.target).closest('li')
          li.attr('data-order', 'desc')
          @update_attribute_order_button li
      else
        order_button.append("<i class='icon-caret-down'> ")
        order_button.on 'click', (e) =>
          li = $(e.target).closest('li')
          li.attr('data-order', 'asc')
          @update_attribute_order_button(li)

  remove_attribute_from_list: (e) ->
    e.preventDefault()

    li = $(@).closest("li")

    # Remove status in all attributes list
    original_attribute = $(".all_attributes dt[data-name='" + li.attr('data-name') + "']")
    if li.closest(".selected_attributes").size() > 0
      original_attribute.removeClass("text-info")
    else
      original_attribute.removeClass("text-warning")

    # Re-add placeholder if the last element is going to be removed.
    if li.closest('ol').find('li').length == 1
      li.closest('ol')
        .append("<li class='placeholder searchable orderable'>#{I18n.t('directory.views.fields.drag_and_drop_me')}</li>")

    li.remove()

  update_attribute_statuses: ->
    attributes = $('.all_attributes dl')
    selected_attributes = @get_selected_attributes()
    attributes_order = []
    for obj in @get_attributes_order()
      attributes_order.push k for k,v of obj

    attributes.find("dt").each (index, dt) =>
      dt = $(dt)

      # change status if attributes is in another list
      if selected_attributes.indexOf(dt.data('name')) > -1
        dt.addClass('text-info') if dt.closest(".selected_attributes").length == 0

      if attributes_order.indexOf(dt.data('name')) > -1
        dt.addClass('text-warning') if dt.closest(".attributes_order").length == 0

  get_selected_attributes: ->
    # an array of strings... the jquery way
    $("#presets").find(".selected_attributes li").map( ->
      $(@).data('name')
      ).get()

  get_attributes_order: ->
    # an array (sorted, not an object) of pairs 'attr': 'asc|desc'...
    # the coffescript way
    for li in $("#presets").find(".attributes_order li")
      continue unless $(li).data('name')
      obj = {}
      # ? data('order') not working
      obj[$(li).data('name')] = $(li).attr('data-order')
      obj

  # external method, context may change
  get_filters: ->
    a = {}
    a['search_string'] = $("#search_string").val()
    a['attributes_order'] = @get_attributes_order()
    a['selected_attributes'] = @get_selected_attributes()
    a

class Search extends SearchEngineExtention
  events:
    'submit form':                                'search'
    'click button[name=directory-search]':        'search'
    'click button[name=directory-custom-action]': 'call_custom_action' # It may not exists
    'click button[name=directory-preset-edit]':   'toggle_edit'
    'change #directory_presets_selector':         'load_preset'

  constructor: (params) ->
    super

  active: (params) =>
    @query_preset = params.preset if params.preset
    @render()

  render: =>
    # Search may load before Edit (presets)
    if $("#presets").length > 0
      current_toggle_status = $("#presets").hasClass('collapse')
    else
      current_toggle_status = true

    @html @view('directory/search_engine/search')(@)
    @el.find('#search_string').keypress (e) =>
      if (e.which == 13)
        @el.find('input[type=submit]').click()

    $("#presets_summary").collapse(toggle: ! current_toggle_status)

    # Select the right preset
    $("#directory_presets_selector")
      .find("option[data-id=#{@query_preset.id}]")
      .prop(selected: 'selected')

    # Disabled requested fields
    if @custom_action and @custom_action.disabled.indexOf('search_string') != -1
      $("#search_string").attr(disabled: true)
      # If search_string is disabled you probably want to see preset
      setTimeout (-> $("button[name=directory-preset-edit]").click()), 500

  search: (e) ->
    e.preventDefault()
    if @custom_action
      Directory.search_with_custom_action @get_filters(),
        url: @custom_action.url
        title: @custom_action.title
        message: @custom_action.message
    else
      Directory.search @get_filters()

  call_custom_action: (e) ->
    e.preventDefault()
    # Redirect to the given url using POST
    form = $("<form action='#{@custom_action.url}' method='post' id='directory_custom_action'>")
    query = $("<input type='hidden' name='query' value='#{JSON.stringify(@get_filters())}'>")
    auth_token = $("<input type='hidden' name='authenticity_token' value='#{App.authenticity_token()}'>")
    form.append query, auth_token
    $('body').append form
    form.submit()

  load_preset: (e) ->
    e.preventDefault()
    @query_preset = $(e.target).query_preset()

    # Keep custom action search_string if existing
    if @custom_action and @custom_action.search_string
      @query_preset.query.search_string = @custom_action.search_string

    @trigger 'edit', {preset: @query_preset}
    @render()

class Edit extends SearchEngineExtention
  events:
    'click button[name=directory-preset-update]':  'update'
    'click button[name=directory-preset-add]':     'add'
    'click button[name=directory-preset-destroy]': 'destroy'
    'click button[name=directory-preset-close]':   'toggle_edit'

  constructor: (params) ->
    super

  active: (params) =>
    @query_preset = params.preset if params.preset
    @render()

  render: =>
    current_toggle_status = $("#presets").hasClass('in')
    @html @view('directory/search_engine/presets')(@)
    $("#presets").collapse(toggle: current_toggle_status) # Do not display annimation on loading

    # Disabled requested fields
    if @custom_action
      if @custom_action.disabled.indexOf('selected_attributes') != -1
        $("#presets .selected_attributes")
          .closest('.panel')
          .addClass('panel-disabled')
          .removeClass('panel-default')

      if @custom_action.disabled.indexOf('attributes_order') != -1
        $("#presets .selected_attributes")
          .closest('.panel')
          .addClass('panel-disabled')
          .removeClass('panel-default')

    @load_jquery_ui_interactions()

  update: (e) =>
    e.preventDefault()
    # special form, using custom methods here instead of fromForm
    @query_preset.query = @get_filters()
    @query_preset.name = $("#directory_preset_name").val()
    @save_with_notifications @query_preset, =>
      @trigger 'edit', preset: @query_preset # Update preset selector
      @render()
      $("#directory_preset_edit_title").addClass('text-success')
      restore_panel_status = ->
        $("#directory_preset_edit_title").removeClass 'text-success', {duration: 3000, easing: 'easeInOutCubic'}

      setTimeout(restore_panel_status, 3000)

  add: (e) =>
    e.preventDefault()
    new_query_preset = new QueryPreset()
    new_query_preset.query = @get_filters()
    new_query_preset.name = $("#directory_preset_name").val()
    @save_with_notifications new_query_preset, (id) =>
      @query_preset = QueryPreset.find id
      @trigger 'edit', preset: @query_preset
      @render()

  destroy: (e) =>
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @query_preset, =>
        @trigger 'destroyed'

class Index extends App.ExtendedController
  events:
    'click tr.item td:not(.ignore-click)': 'edit'
    'click tr button[name=directory-person-destroy]': 'destroy'
    'click tr button[name=directory-person-change-password]': 'change_password'
    'click a[name=directory-export-to-csv]': 'export_to_csv'
    'click a[name=directory-map]': 'open_map'

  constructor: (params) ->
    super
    @json_query = $('#directory_json_query').val()
    @query = $.parseJSON(@json_query)

  active: (params) ->
    @render()

  render: =>
    @results_count = $("#directory_results_count").val()

    @html @view('directory/search_engine/index')(@)

    table = @el.find("#results")
    # Add table class for styling. It is not in the view to prevent Ui.load_ui from loading the table.
    table.addClass('datatable')

    extended_params =
      bFilter: false # disable search field
      sAjaxSource: Directory.search_url(@query)
      fnServerData: (sSource, aoData, fnCallback) =>
        $.ajax
          dataType: 'json'
          url: sSource
          data: aoData
          success: fnCallback
          error: (xhr) =>
            @render_errors($.parseJSON(xhr.responseText))
            empty =
              "sEcho": 1
              "iTotalRecords": 0
              "iTotalDisplayRecords": 0
              "aaData": []
            fnCallback(empty)

    Ui.datatable_bootstrap_classes(table)
    Ui.datatable_localstorage(table)
    table.dataTable Ui.datatable_params(table, extended_params)
    Ui.datatable_appareance(table, {sorting: false})

  export_to_csv: (e) =>
    e.preventDefault()
    window.location = '/directory.csv?query=' + @json_query

  edit: (e) =>
    e.preventDefault()
    id    = $(e.target).directory_person_id()
    table = @el.find("#results").dataTable()
    index = table.fnSettings()._iDisplayStart + table.fnGetPosition(e.target)[0]
    # TODO index not working
    window.location = '/people/paginate?query=' + @json_query + '&index=' + index

  destroy: (e) =>
    e.preventDefault()
    id    = $(e.target).directory_person_id()
    table = @el.find("#results").dataTable()
    index = table.fnSettings()._iDisplayStart + table.fnGetPosition(e.target)
    if confirm(I18n.t("common.are_you_sure"))
      $.ajax
        type: "delete"
        url: '/people/' + id + ".json"
        data: "id=#{id}"
        datatype: 'json'
        success: (msg) =>
          window.location.reload()
        error: (msg) =>
          window.location = '/people/paginate' +
                            '?query=' + @json_query +
                            '&index=' + index

  change_password: (e) =>
    e.preventDefault()
    id = $(e.target).directory_person_id()
    window.location = '/people/' + id + '/change_password'

  open_map: (e) =>
    e.preventDefault()
    window.open '/directory/map.html?query=' + @json_query, 'directory_map'

class App.DirectorySearchEngine extends App.ExtendedController
  constructor: (params) ->
    super

    @json_query = $('#directory_json_query').val()
    @query = $.parseJSON(@json_query)

    @search = new Search
    @edit = new Edit
    @index = new Index
    @append(@search, @edit, @index)

    @search.bind 'edit', (p) =>
      @edit.active(preset: p.preset)

    @edit.bind 'edit', (p) =>
      @search.active(preset: p.preset)

    @edit.bind 'destroyed', =>
      @edit.active(preset: QueryPreset.first())
      @search.active(preset: QueryPreset.first())

  activate: ->
    super
    QueryPreset.one 'refresh', =>
      qp = new QueryPreset(query: @query)
      @search.active(preset: qp)
      @edit.active(preset: qp)
      @index.active(preset: qp)

    SearchAttribute.one 'refresh', =>
      QueryPreset.fetch()

    # Do not use index but searchable method
    SearchAttribute.fetch(url: "#{SearchAttribute.url()}/searchable")
