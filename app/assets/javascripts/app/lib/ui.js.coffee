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

# This comment was in tasks/form.jst.hamlc
#
# Notes on sortable table with context menu
#
# Requirements:
# Command menu must have class as below
# each command tag requires 'data-label' and 'date-icon' attributes which are
# used by jQuery Contextmenu plugin to name the entry in the contextmenu, and
# to set an icon, respectively.
# The required 'data-event' define which event name is triggered by context-
# menu's callback. This event should exist in the current Spine Controller.
#
# Every single <tr> require a 'data-id' attribute which is used by the .fn.task
# jQuery extention described on top of Spine controller. This allow every
# method to retreive the current task id.
#
# table's classes should include 'datatable' class to load the datatable
# plugin and 'with_contextmenu' to load contextmenu plugin.

# TODO: Make it a nice class and extend App with it
class Ui
  constructor: ->

  load_ui: (context) =>
    @load_jqueryui(context)
    @load_autocompleters(context)
    @load_multi_autocompleters(context)
    @load_wysiwyg(context)
    @load_number_precision(context)
    @load_password_strength(context)
    @load_panels(context)

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

    # $(document).delegate 'input[type="date"]', 'focus', ->
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
    # $.fn.dataTableExt.oStdClasses.sSortable = "glyphicon glyphicon-sort";

#--- ui ---
  load_jqueryui: (context) ->
    context.find('.set_focus').focus()

    # datatables
    context.find('.datatable').each (index, table) =>
      @load_datatable $(table)

    # requied fields
    $('input.required, textarea.required').siblings('label').addClass('required')
    # $('input.required').attr("required", true) # this enable HTML5 validation, might conflict with datepicker.

  load_datatable: (table) ->
    # ensure datatable isn't already loaded on this table
    if table.closest(".dataTables_wrapper").length == 0
      # Extend table with bootstrap classes
      table.addClass("table table-hover table-condensed table-responsive")

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

    params =
      oLanguage: I18n.datatable_translations # TODO scope like I18n.datatable_translations[I18n.locale]
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
    parent = label.parent()
    label.remove()
    parent.addClass('panel-body')
    parent.append search_input
    search_input.attr('placeholder', I18n.datatable_translations['sSearch'])
    search_input.addClass('form-control input-sm')

    # SORTING
    table.find('th.sorting').prepend("<span class='glyphicon glyphicon-sort'/>&nbsp;")
    table.find('th.sorting_asc').prepend("<span class='glyphicon glyphicon-sort-by-attributes'/>&nbsp;")
    table.find('th.sorting_desc').prepend("<span class='glyphicon glyphicon-sort-by-attributes-alt'/>&nbsp;")

    table.find('th.sorting, th.sorting_desc, th.sorting_asc').on 'click', (e) ->

      # reset all columns
      table.find('th.sorting, th.sorting_desc, th.sorting_asc').each (index, i) ->
        th = $(i)
        th.find('span.glyphicon').remove()
        icon = $("<span class='glyphicon glyphicon-sort'/>")
        th.prepend icon

      th = $(e.target)
      th.find('span.glyphicon').remove()
      icon = $("<span class='glyphicon'/>")
      th.prepend icon
      if th.hasClass('sorting_asc')
        icon.removeClass('glyphicon-sort-by-attributes-alt')
        icon.addClass('glyphicon-sort-by-attributes')
      else
        icon.removeClass('glyphicon-sort-by-attributes')
        icon.addClass('glyphicon-sort-by-attributes-alt')


  load_password_strength: (context) ->
    # display password strength on .strong_password input[type=password] fields
    if context.find('.strong_password').length > 0
      $.strength '#person_email', '#person_password.strong_password', (email, password, strength) ->
        div = $(password).next('div.strength')

        if (!div.length)
          $(password).after('<div class="strength">')
          div = $('div.strength')

        $(div).removeClass('weak')
              .removeClass('good')
              .removeClass('strong')
              .addClass(strength.status)
              .html(strength.status)

#--- ui tools ---
  load_panels: (context) =>
    context.find('.panel').each (index, panel) =>
      $(panel).trigger('load-panel') # trigger it when loading page

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

      unless text_field.attr('action')
        console.error "'action=url' attribute missing."

      select_callback = (event, ui) ->
        hidden_field.attr('value', ui.item.id)

      keydown_callback = (event) ->
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
    tinyMCE.init
      mode: 'specific_textareas',
      editor_selector: 'wysiwyg',
      width: '100%',
      height: '1250px',
      valid_children : '+body[style]',
      language: I18n.locale,
      body_class: 'a4_page',
      content_css: ['/assets/resetter.css', '/assets/custom_fonts.css', '/assets/pdf_common.css', '/assets/pdf_preview.css'],
      plugins: 'autoresize,fullscreen,table,autolink,lists,spellchecker,pagebreak,style,layer,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,noneditable,visualchars,nonbreaking,xhtmlxtras,template',
      theme: 'advanced',
      theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
      theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor",
      theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen",
      theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,spellchecker,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,blockquote,pagebreak,|,insertfile,insertimage",
      theme_advanced_toolbar_location : "top",
      theme_advanced_toolbar_align : "left",
      theme_advanced_statusbar_location : "bottom",
      theme_advanced_resizing : true

#--- fix html input type number precision ---
  load_number_precision: (context) ->
    context.find('input[type="number"]').each ->
      value = $(@).attr('value')
      num = parseFloat(value)
      decimal = value.split(".")[1]
      if decimal
        if decimal.length < 2 # FIXME: Could it be a comma on certain localization ?
          $(@).attr('value', num.toFixed(2))
      else
        $(@).attr('value', num.toFixed(2))

window.Ui = new Ui
