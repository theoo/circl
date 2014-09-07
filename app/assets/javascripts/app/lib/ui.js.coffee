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

# TODO: Make it a nice class and extend App with it
class Ui
  constructor: ->

  load_ui: (context) =>
    @load_jqueryui(context)
    @load_autocompleters(context)
    @load_multi_autocompleters(context)
    @load_number_precision(context)
    @load_password_strength(context)
    @override_rails(context)
    @timout_info_alerts(context)

    # FIXME http://getbootstrap.com/javascript/#tooltips the event
    # should be trigged without calling this line (?)
    $('a[data-toggle=tooltip]').tooltip()

  initialize_ui: =>
    @load_locale()
    @bind_datepicker()
    @bind_currency_selector()
    @setup_datatable()
    @load_back_on_top()

#--- delegated to events ---
  bind_datepicker: ->
    # Fields type='date' should not be used anymore. There is
    # too much incompatibility between browsers with it (specially localisation problems)
    # $(document).delegate 'input[type="date"]', 'click', (e) ->
    #  e.preventDefault() # disable HTML5 default behavior

    # If an ID is given to the datepicker, ensure it's really unique
    # and not in a hidden form (like it is with spine new/edit paradigm)

    $(document).delegate 'input.datepicker', 'focus', ->
      $(@).datepicker
        inline: true
        buttonImageOnly: true
        showTime: true
        showWeek: true
        firstDay: 1
        showOtherMonths: true
        selectOtherMonths: true
        showButtonPanel: true
        showOptions:
          direction: "up"
        dateFormat: "dd-mm-yy"

  bind_currency_selector: ->
    $(document).on 'change', 'select.currency_selector', (e) ->
      value_input        = $(e.target).closest(".input-group").find("input[type=number]")
      ref_currency_input = $(e.target).siblings("input[name=reference_currency]")
      ref_value_input    = $(e.target).siblings("input[name=reference_value]")

      # When object is new, there is no reference value
      unless ref_currency_input.val()
        ref_currency_input = $(e.target).closest(".input-group").find("input[name=value_currency]")

      unless ref_value_input.val()
        val = $(e.target).closest(".input-group").find("input[name=value]").val()
        ref_value_input.val(val)

      data =
        target_currency: $(e.target).val()
        reference_currency: ref_currency_input.val()
        reference_value: ref_value_input.val()

      success = (d) ->
        value_input.val(d.target_value)
        $(e.target).trigger 'currency_changed' # Catch this in 'events:'

      $.get "/settings/currency_rates/exchange", data, success, 'json'

#--- translations ---
  load_locale: ->
    # set default locale for i18n-js
    I18n.defaultLocale = $('html').attr('lang')
    I18n.locale = $('html').attr('lang')

#--- datatables setup ---
  setup_datatable: ->
    # $.fn.dataTableExt.oStdClasses.sSortable = "icon-sort"

#--- ui ---
  load_jqueryui: (context) ->
    # Set focus on input with .set_focus class
    context.find('.set_focus').focus()

    # Load datatables
    context.find('.datatable').each (index, table) =>
      @load_datatable $(table)

    # Mark required fields
    context.find('input.required, textarea.required, select.required').each ->
      label = $(@).siblings('label')
      # In some case (input-groups) label is on the upper level of input
      label = $(@).parent().siblings('label') if label.length == 0

      label.addClass('required')

    # $('input.required').attr("required", true) # this enable HTML5 validation, might conflict with datepicker.

    # Add icon to datepickers
    dp = context.find('input.datepicker')
    if dp.length > 0
      dp.each ->
        parent = $(@).closest('.form-group')
        # label = parent.find('label')
        input_group = $("<span class='input-group'>")
        input_addon = $("<span class='input-group-addon'>")
        icon = $("<span class='icon-calendar'>")
        input_addon.append icon
        input_group.append $(@)
        input_group.append input_addon
        parent.append input_group

  override_rails: (context) ->
    context.find('.field_with_errors').each ->
      $(@).closest('.form-group').addClass('has-error')

  timout_info_alerts: (context) ->
    context.find('.alert.alert-info.timoutable').each (i, e) ->
      # Wait 5 seconds and fadeOut the message in 1 second
      setTimeout( (-> $(e).fadeOut(1000); return), 5000 )

  datatable_bootstrap_classes: (table) ->
    # Extend table with bootstrap classes
    table.addClass("table table-hover table-condensed table-responsive")

  datatable_localstorage: (table) ->
    # get panel name to scope localstorage entry (datatable state)
    # it is required to set a "name" attribute when two tables are
    # displayed in the same panel.
    panel_id = table.closest('.panel').attr('id')
    table_name = table.attr('name')

    if table_name == undefined
      if panel_id == undefined
        panel_name = 'datatable' + window.location.pathname
      else
        panel_name = 'panel_datatable_' + panel_id
    else
      panel_name = 'panel_datatable_' + table_name

    # callbacks to save and load in localstorage
    @datatable_local_storage_save_callback = (oSettings, oData) ->
      localStorage.setItem(panel_name, JSON.stringify(oData))
    @datatable_local_storage_load_callback = (oSettings) ->
      return JSON.parse(localStorage.getItem(panel_name))


  datatable_params: (table, overloaded_params = {}) ->
    # TODO Use something like this plus bSortable to disable sorting on specific columns
    # default sorting option (class .desc or .asc on <th>)
    # will apply only if previous state isn't saved in localstorage
    sort_parameter = [0, 'asc'] # desfault if no .desc or .asc class is set
    table.find('th').each (index, th) ->
      th = $(th)
      sort_parameter = if th.hasClass('desc')
        [index, 'desc']
      else if th.hasClass('asc')
        [index, 'asc']
      else
        sort_parameter

    datatable_translations = $.extend {}, I18n.datatable_translations # clone object
    datatable_translations.sSearch = '' # Temporarly disable search label, applied to placeholder afterward.

    params =
      oLanguage: datatable_translations # TODO scope like I18n.datatable_translations[I18n.locale]
      aaSorting: [sort_parameter]
      bStateSave: true
      # bPaginate: true
      fnStateSave: @datatable_local_storage_save_callback
      fnStateLoad: @datatable_local_storage_load_callback
      bJQueryUI: false # We'll use bootstrap only, not the ui-state-default classes mess
      sPaginationType: 'bootstrap'
      fnDrawCallback: (oSettings) -> @trigger('datatable_redraw'), # Catch this in Spine!
      sDom: "<'row'<'col-xs-3 col-lg-5 form-inline'lr><'col-xs-9 col-lg-7'f>><'datatable_wrapper't><'panel-body'<'row'<'col-md-12 pagination-footer'pi>>"

    action = table.attr('action')
    if action
      $.extend params,
        bProcessing: true
        bServerSide: true
        sAjaxSource: action
        fnRowCallback: (row, data, index) =>
          $(row).attr('data-id', data.id)

          # make it nice and clickable
          $(row).addClass('item')

          # add custom classes
          if data.classes
            $(row).addClass(data.classes)

          # display trees
          if data.level
            $(row).addClass("level" + data.level)
            $(row).addClass("child") if data.level > 0

          # apply special style to number columns
          if data.number_columns
            tds = $(row).find('>td')
            for i in data.number_columns
              $(tds[i]).addClass('number')

          # apply special style to action columns
          if data.action_columns
            tds = $(row).find('td')
            for i in data.action_columns
              $(tds[i]).addClass('ignore-click')

          $(row).attr("title", data.title) if data.title

    if overloaded_params
      $.extend params, overloaded_params

    # return params
    params

  datatable_appareance: (table, params = {sorting: true}) ->
    # Customize appearance

    # SEARCH - Add the placeholder for Search and Turn this into in-line formcontrol
    search_input = table.closest('.dataTables_wrapper').find('div[id$=_filter] input')
    label = search_input.parent()

    # Override bootstrap inline-block
    # input is inside a label (!), moving input one level higher and removing label cause event
    # not to work.
    label.attr(style: 'display: block;')

    parent = label.parent()
    parent.addClass('panel-body')
    search_input.attr('placeholder', I18n.datatable_translations.sSearch)
    search_input.addClass('form-control input-sm')

    length_select = table.closest('.dataTables_wrapper').find('div[id$=_length] select')
    length_select.addClass('form-control input-sm')
    parent = length_select.parent().parent()
    parent.addClass('panel-body form-group')

    # SORTING
    if params.sorting
      table.find('th.sorting:not(.ignore-sort)').append("&nbsp;<span class='icon-sort'/>")
      table.find('th.sorting_asc').append("&nbsp;<span class='icon-sort-up'/>")
      table.find('th.sorting_desc').append("&nbsp;<span class='icon-sort-down'/>")

      table.find('th.sorting:not(.ignore-sort), th.sorting_desc, th.sorting_asc').on 'click', (e) ->

        # reset all columns
        table.find('th.sorting:not(.ignore-sort), th.sorting_desc, th.sorting_asc').each (index, i) ->
          th = $(i)
          th.find('span.icon-sort, span.icon-sort-up, span.icon-sort-down').remove()
          icon = $("<span class='icon-sort'/>")
          th.append icon

        th = $(e.target)
        th.find('span.icon-sort').remove()
        icon = $("<span class='icon-sort'/>")
        th.append icon
        if th.hasClass('sorting_asc')
          icon.removeClass('icon-sort-down')
          icon.addClass('icon-sort-up')
        else
          icon.removeClass('icon-sort')
          icon.addClass('icon-sort-down')

  load_datatable: (table) ->
    # ensure datatable isn't already loaded on this table
    if table.closest(".dataTables_wrapper").length == 0

      @datatable_bootstrap_classes(table)
      @datatable_localstorage(table)
      table.dataTable @datatable_params(table)
      @datatable_appareance(table)


  load_tabs: (context, on_tab_change_callback = undefined) ->
    nav = context.find("#sub_nav")
    nav.find("a").click (e) ->
      e.preventDefault()
      $(@).tab('show')

    get_tab_name = (tab) ->
      hash = tab.attr('href').split('#')
      hash[1].split("_")[0] if hash.length > 1

    title = nav.find("a")

    title.on 'shown.bs.tab', (e) ->
      tab_name = get_tab_name($(e.target))

      # Update url location in browser
      location.hash = tab_name if tab_name

      # Update info tab name
      $("#tab_name").html(nav.find("li.active a").html())

      # Run callback if given
      if on_tab_change_callback
        on_tab_change_callback()

    title.one 'show.bs.tab', (e) ->
      tab_name = get_tab_name($(e.target))
      # Trigger tab content loading (which is caught in index.js.coffee)
      nav.trigger tab_name

    anchor = location.hash.split('#')
    anchor = anchor[1] if anchor

    tab_link = nav.find("a[href=#" + anchor + "_tab]")
    tab_link = nav.find("a:first") if tab_link.length == 0
    tab_link.tab('show')

  load_password_strength: (context) ->
    # display password strength on .strong_password input[type=password] fields
    if context.find('.strong_password').length > 0
      $.strength '#person_email', '#person_password.strong_password', (email, password, strength) ->
        div = $("#password_strength")

        if (!div.length)
          $(password).after('<div class="strength">')
          div = $('div.strength')

        switch strength.status
          when 'weak'
            strength_class = 'label-danger'
            strength_title = I18n.t("common.weak")
          when 'good'
            strength_class = 'label-warning'
            strength_title = I18n.t("common.good")
          when 'strong'
            strength_class = 'label-success'
            strength_title = I18n.t("common.strong")

        $(div).removeClass('label-danger label-warning label-success')
              .addClass(strength_class)
              .html(strength_title)

  load_back_on_top: () ->
    offset = 220
    duration = 500
    button = $("<a href=\"#\" class=\"back-to-top\"><i class=\"icon icon-angle-up\"></i></a>")
    button.appendTo "body"
    jQuery(window).scroll ->
      if jQuery(@).scrollTop() > offset
        jQuery(".back-to-top").fadeIn duration
      else
        jQuery(".back-to-top").fadeOut duration

    jQuery(".back-to-top").click (e) ->
      e.preventDefault()
      jQuery("html, body").animate scrollTop: 0 , duration
      false


#--- Autocompleters ---
  load_autocompleters: (context) ->
    context.find('div.autocompleted').each (index, div) ->
      div = $(div)
      text_field = div.find("input[type='search']")
      hidden_field = div.find("input[type='hidden']")

      # Some style
      unless div.find('.autocomplete-icon').length > 0
        label = div.find("label")
        icon = $('<span class="icon icon-search autocomplete-icon"></span>')
        label.prepend icon

      unless text_field.attr('action')
        console.error "'action=url' attribute missing."

      select_callback = (event, ui) ->
        hidden_field.attr('value', ui.item.id)
        text_field.attr('value', ui.item.title) if ui.item.title
        # $(event.target).trigger "selected", [event, ui]

      keydown_callback = (event) ->
        if $(@).data('autocomplete')
          event.preventDefault() if event.keyCode == $.ui.keyCode.TAB and $(@).data('autocomplete').menu.active

      blur_callback = (event) ->
        if @value.length == 0
          hidden_field.attr('value', null)

      # We bind on 'blur' instead of 'change' because 'change'
      # uses setTimeout and thus fires after 'submit', reseting
      # the hidden field too late
      text_field.bind('keydown', keydown_callback)
                .bind('blur', blur_callback)
                .autocomplete
                  source: text_field.attr('action')
                  select: select_callback
                .data("ui-autocomplete")._renderItem = (ul, item) ->
                  if item.title or item.desc
                    content = $("<a><b>#{item.label}</b></a>")
                  else
                    content = $("<a>#{item.label}</a>")

                  if item.title
                    content.append(" <i>#{item.title}</i>")

                  if item.desc and item.desc != item.label
                    content.append("<br/>#{item.desc}")

                  $("<li>").append(content).appendTo(ul)


  load_multi_autocompleters: (context) ->
    context.find('div.multi_autocompleted').each (index, div) ->
      div = $(div)
      text_field = div.find("input[type='search']")
      hidden_field = div.find("input[type='hidden']")

      split = (val) ->
        return val.split( /,\s*/ )

      extract_last = (term) ->
        return split(term).pop()

      source_callback = (request, response) ->
        $.getJSON text_field.attr('action'), term: extract_last(request.term), response

      search_callback = ->
        # custom minLength
        term = extract_last(@value)
        return false if term.length < 1

      focus_callback = ->
        # prevent value inserted on focus
        return false

      select_callback = (event, ui) ->
        terms = split @value
        # remove the current input
        terms.pop()
        # add the selected item
        terms.push ui.item.value
        # add placeholder to get the comma-and-space at the end
        terms.push ''
        @value = terms.join ', '

        # TODO remove this whole block, it seems unused
        if hidden_field.length > 0 # check if selector match a dom object
          hv = hidden_field.attr 'value'
          string = if hv then hv.match(/(\[)(.*)(\])/)[2] else null
          ids = if string then split(string) else []
          ids.splice(0,1) if (ids[0] == "")
          ids.push ui.item.id
          that_hidden_field.attr('value', '[' + ids.join(', ') + ']')

        return false

      bind_callback = (event) ->
        event.preventDefault() if event.keyCode == $.ui.keyCode.TAB and $(@).data('autocomplete').menu.active

      # don't navigate away from the field on tab when selecting an item
      text_field.bind('keydown', bind_callback).autocomplete
        source: source_callback
        search: search_callback
        focus:  focus_callback
        select: select_callback

#--- in page tools ---
  build_modal: (uniq_id, options = {}) ->
    # build a new target div if not existing
    win = $("#" + uniq_id)
    win = $("<div class='modal fade' id='"+uniq_id+"' tabindex='-1' role='dialog' />") unless win.length > 0

    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

  stack_window: (uniq_id, options = {}) ->
    # build a new target div if not existing
    win = $("#" + uniq_id)
    win = $("<div class='dialog' id='"+uniq_id+"' />") unless win.length > 0

    ui = @

    # make this div beeing a window
    defaults =
      modal: true
      draggable: true
      resizable: false
      dialogClass: 'widget'
      beforeClose: ->
        # remove opened datepickers
        $(@).find('input.datepicker').each -> $(@).datepicker("destroy")
        # release submit button
        ui.unlock_submit $(@)
        $(@).parent().find('.notice, .error').text("")
        $(@).remove() if options.remove_on_close
        options.remove_callback(@) if options.remove_callback
      show: 'fade'
      hide: 'fade'
      autoOpen: false

    if options.title
      defaults = $.extend({}, defaults, {title: options.title})

    if options.fullscreen
      fullscreen =
        height: $(document).height(),
        width: $(document).width() - 20,
        position: ['top', 'center']
      defaults = $.extend({}, defaults, fullscreen)

    if options.width
      defaults = $.extend({}, defaults, {minWidth: options.width})

    if options.height
      defaults = $.extend({}, defaults, {minHeight: options.height})

    if options.position
      defaults = $.extend({}, defaults, {position: options.position})

    return(win)

  load_map: (container_string, save_callback = undefined) ->
    map_container = $("#" + container_string)
    map_height = $(document).height() - 265
    map_height = 300 if map_height < 300

    map_container.css(height: map_height)

    coordinates = $($.parseJSON $("[name=map_markers]").val())
    config = $.parseJSON $("[name=map_config]").val()

    map = L.map(container_string)
    markers = []

    # There is one marker
    if coordinates.length == 1
      marker = coordinates[0]
      map.setView(marker.latlng, config.max_zoom)
      m = L.marker(marker.latlng, {draggable: true}).addTo(map)
      m.bindPopup(marker.popup)
      m.openPopup()

      m.on 'dragend', (e) ->
        latlng = m.getLatLng()
        latlng_string =[latlng.lat, latlng.lng].join(", ")

        # update latlng input field
        $("#person_geographic_coordinates").val latlng_string

        save_callback(latlng) if save_callback

      markers.push m

    # There is many coordinates
    if coordinates.length > 1
      bounds = []
      coordinates.each ->
        m = L.marker(@.latlng).addTo(map)
        m.bindPopup(@.popup)
        markers.push m
        bounds.push @.latlng

      # Adapt viewport to see all coordinates
      map.fitBounds(bounds)

    L.tileLayer(config.tile_url, {attribution: config.attribution, maxZoom: config.max_zoom }).addTo(map)

    [map, markers]


#--- fix html input type number precision ---
  load_number_precision: (context) ->
    context.find('input[type="number"]').each ->
      value = $(@).attr('value')
      if value
        num = parseFloat(value)
        decimal = value.split(".")[1]
        if decimal
          if decimal.length < 2 # FIXME: Could it be a comma on certain localization ?
            $(@).attr('value', num.toFixed(2))
        else
          $(@).attr('value', num.toFixed(2))

window.Ui = new Ui
