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
    @load_tabs(context)
    @override_rails(context)

    # FIXME http://getbootstrap.com/javascript/#tooltips the event
    # should be trigged without calling this line (?)
    $('a[data-toggle=tooltip]').tooltip()

  initialize_ui: =>
    @load_locale()
    @bind_datepicker()
    @timeout_session()
    @setup_datatable()

#--- delegated to events ---
  bind_datepicker: ->
    # Fields type='date' should not be used anymore. There is
    # too much incompatibility between browsers with it (specially localisation problems)
    # $(document).delegate 'input[type="date"]', 'click', (e) ->
    #  e.preventDefault() # disable HTML5 default behavior

    $(document).delegate 'input.datepicker', 'focus', ->
      $(@).datepicker
        inline: true
        buttonImageOnly: true
        showWeek: true, firstDay: 1
        showOtherMonths: true
        selectOtherMonths: true
        showButtonPanel: true
        showOptions:
          direction: "up"
        dateFormat: "dd-mm-yy"

#--- translations ---
  load_locale: ->
    # set default locale for i18n-js
    I18n.defaultLocale = $('html').attr('lang')
    I18n.locale = $('html').attr('lang')

#--- datatables setup ---
  setup_datatable: ->
    # $.fn.dataTableExt.oStdClasses.sSortable = "glyphicon glyphicon-sort"

#--- ui ---
  load_jqueryui: (context) ->
    # Set focus on input with .set_focus class
    context.find('.set_focus').focus()

    # Load datatables
    context.find('.datatable').each (index, table) =>
      @load_datatable $(table)

    # Mark required fields
    context.find('input.required, textarea.required').siblings('label').addClass('required')
    # $('input.required').attr("required", true) # this enable HTML5 validation, might conflict with datepicker.

    # Add icon to datepickers
    dp = context.find('input.datepicker')
    if dp.length > 0
      dp.each ->
        parent = $(@).closest('.form-group')
        # label = parent.find('label')
        input_group = $("<span class='input-group'>")
        input_addon = $("<span class='input-group-addon'>")
        icon = $("<span class='glyphicon glyphicon-calendar'>")
        input_addon.append icon
        input_group.append $(@)
        input_group.append input_addon
        parent.append input_group

  override_rails: (context) ->
    $('.field_with_errors').each ->
      $(@).closest('.form-group').addClass('has-error')

  load_datatable: (table) ->
    # ensure datatable isn't already loaded on this table
    if table.closest(".dataTables_wrapper").length == 0
      # Extend table with bootstrap classes
      table.addClass("table table-hover table-condensed table-responsive")

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

    # get widget name to scope localstorage entry (datatable state)
    # it is required to set a "name" attribute when two tables are
    # displayed in the same widget.
    widget_id = table.closest('.widget').attr('id')
    table_name = table.attr('name')

    if table_name == undefined
      if widget_id == undefined
        widget_name = 'datatable_' + window.location.pathname
      else
        widget_name = 'widget_datatable_' + widget_id
    else
      widget_name = 'widget_datatable_' + table_name

    # callbacks to save and load in localstorage
    local_storage_save = (oSettings, oData) ->
      localStorage.setItem(widget_name, JSON.stringify(oData))
    local_storage_load = (oSettings) ->
      return JSON.parse(localStorage.getItem(widget_name))

    datatable_translations = $.extend {}, I18n.datatable_translations # clone object
    datatable_translations.sSearch = '' # Temporarly disable search label, applied to placeholder afterward.

    params =
      oLanguage: datatable_translations # TODO scope like I18n.datatable_translations[I18n.locale]
      aaSorting: [sort_parameter]
      bStateSave: true
      fnStateSave: local_storage_save
      fnStateLoad: local_storage_load
      bJQueryUI: false # We'll use bootstrap only, not the ui-state-default classes mess
      sPaginationType: 'bootstrap'
      fnDrawCallback: (oSettings) -> @trigger('datatable_redraw'), # Catch this in Spine!
      sDom: "<'row'<'col-lg-6'T><'col-lg-6'f>r>t<'panel-body'<'row'<'col-lg-12 pagination-footer'pi>>"

    action = table.attr('action')
    if action
      $.extend params,
        bProcessing: true
        bServerSide: true
        sAjaxSource: action
        fnRowCallback: (row, data, index) =>
          $(row).attr('data-id', data.id)
          $(row).attr('data-actions', data.actions)
          $(row).addClass('item') # make it nice and clickable
          if data.level # display trees
            $(row).addClass("level" + data.level)
            $(row).addClass("child") if data.level > 0
          if data.number_columns # apply special style to number_columns
            tds = $(row).find('td')
            for i in data.number_columns
              $(tds[i]).addClass('number')

          $(row).attr("title", data.title) if data.title

    table.dataTable params

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

    # SORTING
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


  load_tabs: (context) ->
    rewrite_url_anchor = (anchor_name) ->
      url = window.location.hash
      params = url.match(/(\?.*)$/)
      params = if params then params[0] else ""
      window.location.hash = anchor_name + params
      # window.location.hash = anchor_name + params
      # TODO prevent browser from scrolling to anchor, it may exist a better solution.
      @.scrollTo(0,0)

    nav = context.find("#sub_nav")
    nav.find("a").click (e) ->
      e.preventDefault()
      $(@).tab('show')

    nav.find("a").on 'shown.bs.tab', (e) ->
      rewrite_url_anchor $(e.target).attr('href')

    anchor = window.location.hash.match(/^(#[a-z]+)\??/)
    anchor = anchor[1] if anchor

    tab_link = nav.find("a[href=" + anchor + "]")
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

#--- ui tools ---
  unpin_widget: (widget) ->

    hide_on_close = false
    # check widget current status
    if widget.hasClass('folded')
      # not using show_content_of here because I don't want to update cookies
      # and have effects
      widget.trigger('unfolded')
      hide_on_close = true

    widget_id = widget.attr('id')
    title = widget.find('>legend').text()
    content = widget.find(".content")

    # callback when closing the fullscreen widget
    repin_widget = (win) =>
      # restore content to original widget
      widget.append $(win).find(".content")
      # if initial widget status was folded, then hide the content
      if hide_on_close
        widget.trigger('folded')
        content.css(display: 'none') # this override deactivate() Spine method

    window_options =
      fullscreen: true,
      draggable: false,
      remove_on_close: false,
      remove_callback: repin_widget

    window = @stack_window('fullscreen_widget_' + widget_id, window_options)
    fullscreen_widget = $(window)
    fullscreen_widget.addClass('fullscreen_widget')

    fullscreen_widget.modal({title: title})
    # move widget content to fullscreen widget
    fullscreen_widget.append content
    # this override deactivate() Spine method
    content.css(display: 'block')

    fullscreen_widget.modal('show')


  cookie_name: 'folding'

  retrieve_cookie: ->
    cookie = $.cookie(@cookie_name)
    values = []
    values = cookie.split('&') if cookie
    return values

#--- Autocompleters ---
  load_autocompleters: (context) ->
    context.find('div.autocompleted').each (index, div) ->
      div = $(div)
      text_field = div.find("input[type='search']")
      hidden_field = div.find("input[type='hidden']")

      # Some style
      label = div.find("label")
      icon = $('<span class="icon icon-search autocomplete-icon"></span>')
      label.prepend icon

      unless text_field.attr('action')
        console.error "'action=url' attribute missing."

      select_callback = (event, ui) ->
        hidden_field.attr('value', ui.item.id)

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


#--- Timeouts ---
  timeout_session: ->
    remaining_time = $("meta[name='session-remaining-time']").attr("content")

    if remaining_time
      redirect = ->
        window.location.reload()

      setTimeout redirect, (remaining_time * 1000)


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

  validate_date_format: (date) ->
    date.match(/^[0-3][0-9]-[0-1][0-9]-[0-9]{1,4}$/)

#--- wysiwyg ---
  load_wysiwyg: (context) ->
    return if context.find('textarea.wysiwyg').size() <= 0
    tinyMCE.baseURL = "/assets/tinymce"
    tinyMCE.init
      mode: 'specific_textareas'
      schema: 'html5'
      editor_selector: 'wysiwyg'
      valid_children : '+body[style]'
      height: $(window).height() - 280 # 280 is guessed
      language: I18n.locale
      body_class: 'a4_page'
      content_css: ['/assets/custom_fonts.css', '/assets/pdf_common.css', '/assets/pdf_preview.css']
      plugins: 'fullscreen,table,autolink,lists,spellchecker,pagebreak,layer,save,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,noneditable,visualblocks,visualchars,nonbreaking,template,anchor,charmap,hr,image,link,emoticons,code,textcolor'
      theme: 'modern'
      browser_spellcheck : true
      object_resizing : true
      visual: true
      resize: false
      menubar: false
      toolbar1: "save cancel | undo redo | cut copy paste searchreplace | link image | table | charmap hr pagebreak | visualaid visualblocks visualchars | code"
      toolbar2: "styleselect formatselect fontselect fontsizeselect forecolor backcolor | bold italic subscript superscript | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent"
      statusbar: true
      font_formats: "Andale Mono=andale mono,times;"+
        "Arial=arial,helvetica,sans-serif;"+
        "Arial Black=arial black,avant garde;"+
        "Book Antiqua=book antiqua,palatino;"+
        "Comic Sans MS=comic sans ms,sans-serif;"+
        "Courier New=courier new,courier;"+
        "Georgia=georgia,palatino;"+
        "Helvetica=helvetica;"+
        "Impact=impact,chicago;"+
        "Symbol=symbol;"+
        "Tahoma=tahoma,arial,helvetica,sans-serif;"+
        "Terminal=terminal,monaco;"+
        "Times New Roman=times new roman,times;"+
        "Trebuchet MS=trebuchet ms,geneva;"+
        "Verdana=verdana,geneva;"+
        "Webdings=webdings;"+
        "Wingdings=wingdings,zapf dingbats;"+
        "Helvetica Neue Light=Helvetica Neue Light;"+
        "Helvetica Neue Italic=Helvetica Neue Italic;"+
        "Helvetica Neue Cap=Helvetica Neue Cap;"+
        "Calibri=Calibri;"+
        "Arial Narrow=Arial Narrow;"+
        "OCR-B=OCR-B;"+
        "Rotis=Rotis;"+
        "Rotis Extra Bold=Rotis Extra Bold;"+
        "Rotis Italic=Rotis Italic;"+
        "Rotis Light=Rotis Light;"+
        "Rotis Light Italic=Rotis Light Italic"

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
