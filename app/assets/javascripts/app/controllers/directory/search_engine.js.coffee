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

class Index extends App.ExtendedController
  events:
    'click tr.item td:not(.ignore-click)': 'edit'
    'click button[name=directory-person-destroy]': 'destroy'
    'click button[name=directory-person-change-password]': 'change_password'
    'click button[name=directory-export-to-csv]': 'export_to_csv'

  constructor: (params) ->
    super

    @json_query = $('#directory_json_query').val()
    @query = $.parseJSON(@json_query)

  render: =>
    @html @view('directory/search_engine/index')(@)

    table = @el.find("#results")
    # Add table class for styling. It is not in the view to prevent Ui.load_ui from loading the table.
    table.addClass('datatable')

    extended_params =
      bFilter: false # disable search field
      sAjaxSource: Directory.search_url(@query)
      fnServerData: (sSource, aoData, fnCallback) ->
        $.ajax
          dataType: 'json'
          url: sSource
          data: aoData
          success: fnCallback
          error: (xhr) ->
            directory.search.render_errors($.parseJSON(xhr.responseText))
            empty =
              "sEcho": 1
              "iTotalRecords": 0
              "iTotalDisplayRecords": 0
              "aaData": []
            fnCallback(empty)

    Ui.datatable_bootstrap_classes(table)
    Ui.datatable_localstorage(table)
    table.dataTable Ui.datatable_params(table, extended_params)
    Ui.datatable_appareance(table)

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

class App.DirectorySearchEngine extends App.ExtendedController
  constructor: (params) ->
    super
    @index = new Index
    @append(@index)

  activate: ->
    super
    @index.render()
