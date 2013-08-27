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

  bind_observers: =>
    @build_columns()

  load_ui: (context) =>
    @load_jqueryui(context)
#    @load_contextmenus(context)
    @load_foldable_widgets(context)
    @load_autocompleters(context)
    @load_multi_autocompleters(context)
    @load_wysiwyg(context)
    @load_number_precision(context)
    @load_password_strength(context)
    @reposition_dialogs()

  initialize_ui: =>
    @setup_all_widgets_actions()
    @load_locale()
    @bind_datepicker()
    @bind_observers()
    @timeout_session()

#--- columns ---
  build_columns: ->
    widgets = $('#content .widget')

    if widgets.length > 0
      # use maximum available width
      $('#content').css('width', "100%")

      # if there is already columns, move widget and remove columns
      if $('#content .column')
        $('#content').append(widgets)
        $('#content .column').remove()

      widget_width = $('.widget').first().width()

      heights_sum = (ws) ->
        ws_sizes = $.map ws, (w, i) -> $(w).outerHeight()
        _.reduce(ws_sizes, ((memo, num) -> return memo + num), 0)

      number_of_columns = Math.floor($('#content').width() / Math.floor(widget_width))
      max_height_by_column = Math.floor(heights_sum(widgets) / number_of_columns)

      column_index = 1
      current_col_height = max_height_by_column

      # append it first so I can get the height.
      col = $("<div id='column#{column_index}' class='column' />")
      $('#content').append(col)

      for w, i in widgets
        col.append(w)

        if ( col.height() >= max_height_by_column and column_index != number_of_columns ) or i == widgets.length
          column_index += 1
          col = $("<div id='column#{column_index}' class='column' />")
          $('#content').append(col)

      # finaly resize #content so I can center it using margin: 0 auto
      column_sizes = $.map $(".column"), (w, i) -> $(w).outerWidth()
      # 3 is a workaround for borders
      content_width = _.reduce(column_sizes, ((memo, num) -> return memo + num + 3), 0)
      $('#content').css('width', content_width)

      # stretch content to the bottom of the page (widget are floating)
      $('#content').append("<div class='block clear' />")

#--- delegated to events ---
  bind_datepicker: ->
    # Fields type='date' should not be used anymore. There is
    # too much incompatibility between browsers with it (specially localisation problems)
    # $(document).delegate 'input[type="date"]', 'click', (e) ->
    #  e.preventDefault() # disable HTML5 default behavior

    # $(document).delegate 'input[type="date"]', 'focus', ->
    $(document).delegate 'input.datepicker', 'focus', ->
      $(@).datepicker
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

#--- ui ---
  load_jqueryui: (context) ->
    context.find('.set_focus').focus()

    # buttons
    context.find('input[type="submit"]').button()

    context.find('input[type="checkbox"]').not('.normal').button()

    context.find('a.button, span.button').button({ text: true })
    context.find('a.add, input[type=submit].add').button({ icons: { primary: "ui-icon-plus" }, text: true })
    context.find('a.remove').button({ icons: { primary: "ui-icon-minus" }, text: false })
    context.find('a.destroy').button({ icons: { primary: "ui-icon-trash" }, text: true })
    context.find('a.edit').button({ icons: { primary: "ui-icon-pencil" }, text: false })
    context.find('a.check').button({ icons: { primary: "ui-icon-check" }, text: false })
    context.find('a.email').button({ icons: { primary: "ui-icon-mail-closed" }, text: false })
    context.find('a.clear, span.clear').button({ icons: { primary: "ui-icon-close" }, text: false })
    context.find('a.refresh, span.refresh').button({ icons: { primary: "ui-icon-refresh" }, text: false })
    context.find('a.thirty, span.thirty').button({ icons: { primary: "ui-icon-arrowrefresh-1-w" }, text: true })
    context.find('a.arrow_left, span.arrow_left').button({ icons: { primary: "ui-icon-arrowthick-1-w" }, text: true })
    context.find('a.arrow_right, span.arrow_right').button({ icons: { secondary: "ui-icon-arrowthick-1-e" }, text: true })

    # widgets
    ui = @
    context.find(".widget").each ->
      widget = $(@)

      legend = widget.find('legend')

      unless widget.hasClass('ui-dialog')
        widget.addClass('ui-widget-content ui-corner-all')
        legend.addClass('ui-widget-header ui-corner-tl ui-corner-tr')
        innerwidth = widget.width() - (legend.outerWidth() - legend.width())
        legend.css('width', innerwidth)

      ui.append_corner_box(legend)

    # rename buttons
    context.find('input[type=submit]').each ->
      $(@).attr value: $(@).data('title')

    # On submit lock submit button (to prevent double send)
    # TODO: migrate this to a delegation
    context.find('form').submit ->
      $(@).find('input[type=submit]', @).not('.no_sending').each ->
        $(@).attr disabled: 'disabled'
        $(@).attr value: I18n.t('common.sending')

    # datatables
    context.find('.datatable').each (index, table) =>
      @load_datatable $(table)

    # requied fields
    $('input.required, textarea.required').siblings('label').addClass('required')
    # $('input.required').attr("required", true) # this enable HTML5 validation, might conflict with datepicker.

    # section headers
    $('h3.section').each ->
      unless $(@).parent().hasClass('section_wrapper')
        $(@).wrap("<div class='section_wrapper'>")


  load_datatable: (table) ->
    # ensure datatable isn't already loaded on this table
    if table.closest(".dataTables_wrapper").length == 0
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
      bJQueryUI: true
      sPaginationType: 'full_numbers'
      sScrollX: '100%'

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
  unlock_submit: (context) ->
    context.find('input[type=submit]').each ->
      $(@).removeAttr 'disabled'
      $(@).attr value: $(@).attr('data-title')

  spin_on: (context) ->
    context.closest('.widget').find('.spinner').show()

  spin_off: (context) ->
    context.closest('.widget').find('.spinner').hide()

  notify: (context, message, kind) ->
    widget = context.closest('.widget')

    # hide previous/others notification without fx
    widget.find(".notification-box").children().css(display: 'none')
    notification = widget.find(".notification-box .#{kind}")
    notification.text message
    notification.fadeIn()

    # we don't want to queue fx here.
    # notification.delay(5000).fadeOut()
    setTimeout (-> notification.fadeOut()), 5000

#--- contextual loading ---
  load_contextmenus: (context) ->
    # TODO: Use delegate
    items = {}

    uniqID = _.uniqueId('cm')

    context.find('menu.context_menu_actions command').each (index, cmd) ->
      context.attr 'data-contextmenu-id', uniqID

      label = $(cmd).attr('data-label')
      icon = $(cmd).attr('data-icon')
      id = $(@).attr('data-id')
      event_name = $(@).attr('data-event')

      if label == 'separator'
        label = 'separator' + _.uniqueId()
        item = "-----"
      else
        item =
          name: label
          icon: icon
          callback: (action, el, pos) -> $(@).trigger(event_name)
          disabled: (a, el) ->
            actions = $(@).attr('data-actions')?.split(',')
            return true unless actions?.indexOf(a) > -1

      items[label] = item

    if Object.keys(items).length > 0
      $.contextMenu
        items: items
        selector: "[data-contextmenu-id=#{uniqID}] table.with_contextmenu tbody tr"


#--- widgets ---
  # TODO refactor this with a real toggled state instead of this mess
  toggle_folding: (widget) ->
    legend = widget.find('legend')
    icon = legend.find('.folding-icon')
    if icon.hasClass(@plus_class)
      @show_minus_icon(widget)
    else
      @show_plus_icon(widget)

  show_plus_icon: (widget) =>
    legend = widget.find('legend')
    icon = legend.find('.folding-icon')
    icon.removeClass(@minus_class)
    icon.addClass(@plus_class)
    widget.removeClass('unfolded')
    widget.addClass('folded')
    widget.trigger('folded')

  show_minus_icon: (widget) =>
    legend = widget.find('legend')
    icon = legend.find('.folding-icon')
    icon.removeClass(@plus_class)
    icon.addClass(@minus_class)
    widget.removeClass('folded')
    widget.addClass('unfolded')
    widget.trigger('unfolded')

  hide_content_of: (widget) =>
    hide_callback = => @show_plus_icon(widget)
    widget.find('>.content').hide 'blind', hide_callback
    @update_folding_cookie(widget.attr('id'), 0)


  show_content_of: (widget) =>
    show_callback = => @show_minus_icon(widget)
    widget.find('>.content').show 'blind', show_callback
    @update_folding_cookie(widget.attr('id'), 1)


  load_foldable_widgets: (context) =>
    @set_folding_class_to_widgets(context)

    @plus_class = 'ui-icon-carat-1-s'
    plus = $("<span class='ui-icon float_right folding-icon'></span>")
    plus.addClass @plus_class

    @minus_class = 'ui-icon-carat-1-n'
    minus = $("<span class='ui-icon float_right folding-icon'></span>")
    minus.addClass @minus_class

    # save context for anonymous callback functions
    ui = @

    context.find('.unfolded').each (index, widget) =>
      widget = $(widget)
      box = widget.find('legend .right-corner-box')

      # append fold icon
      box.append(minus.clone())
      widget.find('legend .folding-icon').toggle((-> ui.hide_content_of(widget)), (-> ui.show_content_of(widget)))

      # prepend the unpin icon to widget toolbar
      if widget.hasClass "pinable"
        box.append $("<span class='ui-icon unpin float_right ui-icon-newwin'></span>")
        widget.find('legend .unpin').on('click', (e) -> ui.unpin_widget(widget))

      @show_content_of(widget)
      widget.trigger('unfolded') # trigger it when loading page

    context.find('.folded').each (index, widget) ->
      widget = $(widget)
      box = widget.find('legend .right-corner-box')

      # append unfold icon
      box.append(plus.clone())
      widget.find('legend .folding-icon').toggle((-> ui.show_content_of(widget)), (-> ui.hide_content_of(widget)))

      # prepend the unpin icon to widget toolbar
      if widget.hasClass "pinable"
        box.append $("<span class='ui-icon unpin float_right ui-icon-newwin'></span>")
        widget.find('legend .unpin').on('click', (e) -> ui.unpin_widget(widget))

    # format global links (on top right)

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


  update_folding_cookie: (key, toggle) ->
    current_values = @retrieve_cookie()

    # pop or push value
    if toggle
      # ensure value doen't exist before poping
      if current_values.indexOf(key) == -1
        current_values.push(key)
    else
      # ensure value exists
      index = current_values.indexOf(key)
      if index > -1
        current_values.splice(index, 1)

    # update cookie
    $.cookie(@cookie_name, current_values.join('&'), {path: '/'})


  set_folding_class_to_widgets: (context) ->
    current_values = @retrieve_cookie()

    context.find('.widget').each ->
      if current_values.indexOf($(@).attr('id')) > -1
        $(@).addClass('unfolded')
      else
        $(@).addClass('folded')

  setup_all_widgets_actions: ->
    $('#expand_all_widgets').click => @expand_all_widgets($(document))
    $('#clip_all_widgets').click => @clip_all_widgets($(document))
    $('#rearrange_widgets').click => @build_columns($(document))
    @iconify_all_widgets_actions($(document))

  expand_all_widgets: (context) ->
    context.find('.folded').each (index, object) =>
      $(object).find('.folding-icon').click()

  clip_all_widgets: (context) ->
    context.find('.unfolded').each (index, object) =>
      $(object).find('.folding-icon').click()

  iconify_all_widgets_actions: (context) ->
    context.find('#clip_all_widgets').button({ icons: { secondary: "ui-icon-carat-1-n" }, text: false })
    context.find('#expand_all_widgets').button({ icons: { secondary: "ui-icon-carat-1-s" }, text: false })
    context.find('#rearrange_widgets').button({ icons: { secondary: "ui-icon-carat-2-e-w" }, text: false })


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

    # win.modal(defaults)
    @append_corner_box win.parent().find(".ui-dialog-titlebar")

    return(win)

  reposition_dialogs: ->
    $('.ui-dialog-content:visible').modal('option', 'position', 'middle')

  append_corner_box: (legend) ->
    if legend.find('.right-corner-box').size() == 0 # it may not be the first time
      right_corner_box = $("<span class='right-corner-box' />")
      notification_box = $("<span class='notification-box'><span class='error' /><span class='notice' /></span>")
      legend.append right_corner_box, notification_box
      # append the spinner to widget toolbar
      spinner = $('<img src="/assets/small_spinner.gif" class="spinner" />')
      right_corner_box.append(spinner)

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
