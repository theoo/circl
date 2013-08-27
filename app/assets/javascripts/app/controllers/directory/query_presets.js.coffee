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

$.fn.query_preset = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  QueryPreset.find(elementID)


class SearchEngineController extends App.ExtendedController
  load_ui: (context) ->
    @context = context.closest(".query_presets")

    # TODO: can I remove this dead code ?
    #form = @context.find("form#search_engine")
    #if form.size() > 0
    #  @override_submit_action(form)

    filter = @context.find('.filter')
    if filter.size() > 0
      @load_filters(filter)

  override_submit_action: (form) ->
    form.on 'submit', (event) =>
      # event.preventDefault()
      result = {}

      # append filter's values
      for key,val of @get_filters(form)
        result[key] = val

      # inject values in form the hard way
      # this is require to keep order
      $('<input />').attr('type', 'hidden')
        .attr('name', 'query')
        .attr('value', JSON.stringify(result))
        .appendTo(form)

      return true

  update_attribute_statuses: (filter)->
    filter = $(".filter") unless filter

    selected_attributes = @get_selected_attributes(filter)
    attributes_order = []
    for obj in @get_attributes_order(filter)
      attributes_order.push k for k,v of obj

    filter.find("li").each ->
      li = $(@)

      # change status if attributes is in another list
      if selected_attributes.indexOf(li.attr('data-name')) > -1
        li.addClass('ui-state-active') unless li.closest(".selected_attributes").size() > 0

      if attributes_order.indexOf(li.attr('data-name')) > -1
        li.addClass('ui-state-highlight') unless li.closest(".attributes_order").size() > 0
    @update_preset_buttons()

  add_remove_button: (li) ->
    unless li.find("button.remove").size() > 0
      remove_button = $("<button class='remove'></button>")
      li.append(remove_button)

      li.find("button.remove")
        .button({ icons: { primary: "ui-icon-close" }, text: true})
        .on('click', @remove_attribute_from_list)

  add_attribute_order_button: (li) ->
    unless li.find("button.order").size() > 0
      order_button = $("<button class='order'></button>")
      li.prepend(order_button)

      if li.attr('data-order') == 'asc'
        li.find("button.order")
          .button({ icons: { primary: "ui-icon-triangle-1-n" }, text: true})
      else
        li.find("button.order")
          .button({ icons: { primary: "ui-icon-triangle-1-s" }, text: true})

  remove_attribute_from_list: ->
    li = $(@).closest("li")
    original_attribute = $(".all_attributes li[data-name='" + li.attr('data-name') + "']")

    if li.closest(".selected_attributes").size() > 0
      original_attribute.removeClass("ui-state-active")
    else
      original_attribute.removeClass("ui-state-highlight")

    li.remove()

    return false

  load_filters: (filter) ->
    filter.find(".sortable")
      .sortable( placeholder: "ui-state-highlight" )
      .disableSelection()

    filter.find("li").addClass("ui-state-default")

    filter.find(".draggable li")
      .draggable(
        helper: 'clone',
        opacity: 0.9)
      .disableSelection()

    class_instance = @

    filter.find(".attributes_order li").each ->
      class_instance.add_attribute_order_button $(@)
      class_instance.add_remove_button $(@)

    filter.find(".selected_attributes li").each ->
      class_instance.add_remove_button $(@)

    class_instance.update_attribute_statuses()


    # toggle not working here with two handler (deprecated)
    # FIXME unbind('click') is because the event was fired twice with passenger, this will do for now
    filter.unbind('click').on "click", ".attributes_order button", ->
      if $(@).closest('li').attr('data-order') == 'asc'
        $(@).button("option", "icons", { primary: "ui-icon-triangle-1-s" })
        $(@).closest('li').attr('data-order', 'desc')
      else
        $(@).button("option", "icons", { primary: "ui-icon-triangle-1-n" })
        $(@).closest('li').attr('data-order', 'asc')

      return false

    attributes_order_drop_callback = (event, ui) ->
      name = $(ui.draggable).attr('data-name')

      if filter.find(".attributes_order li[data-name=" + name + "]").size() == 0 and name != undefined
        $(@).find(".placeholder").remove()

        li = $("<li class='ui-state-default' data-name=" + name + " data-order='asc'></li>")
          .text(ui.draggable.text())
          .appendTo(@)

        class_instance.add_attribute_order_button li
        class_instance.add_remove_button li
        class_instance.update_attribute_statuses()

    selected_attributes_drop_callback = (event, ui) ->
      name = $(ui.draggable).attr('data-name')

      if filter.find(".selected_attributes li[data-name=" + name + "]").size() == 0 and name != undefined
        $(@).find(".placeholder").remove()

        li = $("<li class='ui-state-default' data-name=" + name + " data-order='asc'></li>")
          .text(ui.draggable.text())
          .appendTo(@)

        class_instance.add_remove_button li
        class_instance.update_attribute_statuses()

    $(".attributes_order .droppable").droppable { drop: attributes_order_drop_callback }
    $(".selected_attributes .droppable").droppable { drop: selected_attributes_drop_callback }

  get_selected_attributes: (filter) ->
    # an array of strings
    # the jquery way
    filter.find(".selected_attributes li").map( ->
      $(@).attr("data-name")
      ).get()

  get_attributes_order: (filter) ->
    # an array (sorted, not an object) of pairs 'attr': 'asc|desc'
    # the coffescript way
    for li in filter.find(".attributes_order li")
      continue unless $(li).attr("data-name")
      obj = {}
      obj[$(li).attr("data-name")] = $(li).attr("data-order")
      obj

  # external method, context may change
  get_filters: (context) ->
    filter = context.find(".filter")
    result = {}
    result['search_string'] = $("#search_string").attr('value')
    result['attributes_order'] = @get_attributes_order(filter)
    result['selected_attributes'] = @get_selected_attributes(filter)
    result

  update_preset_buttons: ->
    preset_id = @context.find(".filter input[name='preset_id']").val()
    button = @context.find(".presets li[data-id='" + preset_id + "']" )

    # highlight current preset in presets menu
    button.siblings().removeClass("ui-state-highlight").removeClass("ui-state-active")
    button.addClass("ui-state-highlight")

    # TODO: add class active when drag/droping
    #button.removeClass("ui-state-highlight")
    #button.addClass("ui-state-active")

class Edit extends SearchEngineController
  events:
    'click input[data-action="next"]':    'edit'
    'click input[data-action="update"]':  'update'
    'click input[data-action="add"]':     'add'
    'click input[data-action="destroy"]': 'destroy'

  constructor: (params) ->
    super
    @query_preset = new QueryPreset()
    SearchAttribute.bind('refresh', @render)

  set_preset: (preset) =>
    @query_preset = preset
    @render()

  render: =>
    @search_attributes = @load_search_attributes()
    @html @view('directory/query_presets/form')(@)
    Ui.load_ui(@el)
    @load_ui(@el)

  load_search_attributes: ->
    attributes = {}
    for attr in SearchAttribute.all()
      attributes[attr.group] ||= []
      attributes[attr.group].push(attr.name)
    attributes

  fill_from_form: (query_preset) =>
    query_preset.query = @get_filters(@el)
    query_preset.name = @el.find("input[name='name']").attr('value')

  edit: (e) ->
    e.preventDefault()
    @trigger('edit')

  update: (e) =>
    e.preventDefault()
    # special form, using custom methods here instead of fromForm
    @fill_from_form(@query_preset)
    @save_with_notifications @query_preset, @render

  add: (e) =>
    e.preventDefault()
    query_preset = new QueryPreset()
    @fill_from_form(query_preset)
    @save_with_notifications query_preset, (id) =>
      @set_preset(QueryPreset.find(id))

  destroy: (e) =>
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @query_preset, =>
        @preset = new QueryPreset()
        @render()

class Search extends SearchEngineController
  events:
    'click input[data-action="search"]': 'search'

  constructor: (params) ->
    @query_preset = new QueryPreset()
    super

  set_preset: (preset) =>
    @query_preset = preset
    @render()

  search: (e) ->
    e.preventDefault()
    @trigger('search')

  render: =>
    @html @view('directory/query_presets/search')(@)
    Ui.load_ui(@el)
    @load_ui(@el)
    @el.find('#search_string').keypress (e) =>
      if (e.which == 13)
        @el.find('input[type=submit]').click()

class Index extends SearchEngineController
  events:
    'click ul li.preset': 'edit'

  constructor: (params) ->
    super
    QueryPreset.bind('refresh change', @render)

  render: =>
    @html @view('directory/query_presets/index')(@)
    Ui.load_ui(@el)
    @load_ui(@el)

  edit: (e) ->
    query_preset = $(e.target).query_preset()
    @trigger 'edit', query_preset

class App.DirectoryQueryPresets extends App.ExtendedController
  className: 'query_presets'

  constructor: (params) ->
    super

    @has_search = params.search?
    if @has_search
      @search_text = params.search.text

    @has_edit = params.edit?
    if @has_edit
      @edit_text = params.edit.text

    @index = new Index
    @edit = new Edit(has_next: !@has_search)

    if @has_search
      @search = new Search(text: @search_text)
      @index.bind 'edit', @search.set_preset
      @search.bind 'search', =>
        query_preset = new QueryPreset()
        @edit.fill_from_form(query_preset)
        @trigger 'search', query_preset
        @trigger 'search_query', query_preset.query
      @append(@search)

    @append(@index)

    if @has_edit
      @edit = new Edit(text: @edit_text)
      @index.bind 'edit', @edit.set_preset
      @edit.bind 'edit', =>
        query_preset = new QueryPreset()
        @edit.fill_from_form(query_preset)
        @trigger 'edit', query_preset
        @trigger 'edit_query', query_preset.query
      @append(@edit)

    QueryPreset.bind 'refresh destroy', =>
      query_preset = new QueryPreset()

      # If there exists a QueryPreset, take the first one
      # Make sure to do a deep copy of the query otherwise we'll modify it
      if QueryPreset.count() > 0
        query_preset.query = $.extend(true, query_preset.query, QueryPreset.first().query)

      # If there is a query in the parameters, use that query instead
      # Make sure to extend the existing query so we can reuse the selected_attributes, etc
      query = @get_url_parameter('query')
      if query
        query_preset.query = $.extend(query_preset.query, JSON.parse(query))

      if @has_edit && !QueryPreset.exists(@edit.query_preset.id)
        @edit.set_preset(query_preset)
      if @has_search && !QueryPreset.exists(@search.query_preset.id)
        @search.set_preset(query_preset)

    @index.bind 'destroyError', (id, errors) =>
      if @has_edit
        @edit.active id: id
        unless @has_search
          @edit.renderErrors errors
      if @has_search
        @search.active(id: id)
        @search.renderErrors errors

  activate: ->
    super
    QueryPreset.fetch()
    SearchAttribute.fetch(url: "#{SearchAttribute.url()}/searchable")
    if @has_search
      @search.render()
