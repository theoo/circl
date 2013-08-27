$(document).ready ->
  # index

  # store current query for futher use (exports, pagniation, etc.)
  json_query = $.parseJSON $('input[name="json_query"]').attr('value')

  directory = new App.DirectoryQueryPresets
                    el: $('#search_form')
                    search:
                      text: I18n.t('directory.views.search')
                    edit:
                      text: null

  directory.bind 'search_query', App.search_query
  directory.activate()

  # TODO: Extend ui.js datable configuration instead of rewriting.

  # callbacks to save and load in localstorage
  local_storage_save = (oSettings, oData) ->
    localStorage.setItem("widget_datatable_directory", JSON.stringify(oData))
  local_storage_load = (oSettings) -> 
    return JSON.parse(localStorage.getItem("widget_datatable_directory"))

  results = $('#results')
  results.dataTable
    oLanguage: I18n.datatable_translations # TODO scope like I18n.datatable_translations[I18n.locale]
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    bStateSave: true
    fnStateSave: local_storage_save
    fnStateLoad: local_storage_load
    sAjaxSource: App.directory_url(json_query)
    bSort: false
    sScrollX: '100%'
    sPaginationType: 'full_numbers'
    bFilter: false
    fnRowCallback: ((row, data, index) ->
        $(row).attr('data-id', data.id)
        $(row).attr('data-actions', data.actions) )
    fnServerData: (sSource, aoData, fnCallback) ->
        $.ajax
            dataType: 'json'
            url: sSource
            data: aoData
            success: fnCallback
            error: (xhr) ->
                directory.search.renderErrors($.parseJSON(xhr.responseText))
                empty =
                  "sEcho": 1
                  "iTotalRecords": 0
                  "iTotalDisplayRecords": 0
                  "aaData": []
                fnCallback(empty)

  # contextual menu
  results.bind 'person-show click', (e) ->
    id    = $(e.target).data('id')
    table = results.dataTable()
    index = table.fnSettings()._iDisplayStart + table.fnGetPosition(e.target)
    window.location = '/people/paginate' +
                      '?query=' + App.escape_query(json_query) +
                      '&index=' + index

  results.bind 'person-change-password', (e) ->
    id = $(e.target).data('id')
    window.location = '/people/' + id + '/change_password'

  results.bind 'person-destroy', (e) ->
    id    = $(e.target).data('id')
    table = results.dataTable()
    index = table.fnSettings()._iDisplayStart + table.fnGetPosition(e.target)
    if confirm(I18n.t("common.are_you_sure"))
      $.ajax
        type: "DELETE"
        url: '/people/' + id + ".json"
        data: "id=#{id}"
        datatype: 'json'
        success: (msg) ->
          window.location.reload()
        error: (msg) ->
          window.location = '/people/paginate' +
                            '?query=' + App.escape_query(json_query) +
                            '&index=' + index

  # This bind event on toolbox -> export button
  $('#export_to').on 'click', (e) ->
    format = $(@).data('type')
    window.location = '/directory.' + format +
                      '?query=' + App.escape_query(json_query)
    return false

  # This will load 'new person' widget, if button is present.
  # User may not have access to this widget
  $('#add_new_person').on 'click', (e) ->
    container_id = 'add-new-person'
    widget = Ui.stack_window(container_id, {width: 500, position: ['top', 30], remove_on_close: true})
    people_controller = new App.People({el: widget})
    people_controller.activate()
    widget.modal({title: I18n.t('directory.views.add_person')})
    widget.modal('show')
    Ui.bind_datepicker()

  # finally load ui
  # FIXME: loading Ui.load_ui($(document)) doesn't
  # load the contextual menu on datatable
  Ui.load_ui($("#content"))
  Ui.load_ui($("header"))
