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

class Search extends App.ExtendedController
  events:
    'click button[name=directory-search]': 'search'

  constructor: (params) ->
    super
    #@title = params.title if params and params.title

  active: (params) =>
    @query_preset = params.preset if params.preset
    @render()

  search: (e) ->
    e.preventDefault()
    @trigger('search')

  render: =>
    @html @view('directory/search_engine/search')(@)
    @el.find('#search_string').keypress (e) =>
      if (e.which == 13)
        @el.find('input[type=submit]').click()

class Edit extends App.ExtendedController
  events:
    'click input[data-action="next"]':    'edit'
    'click input[data-action="update"]':  'update'
    'click input[data-action="add"]':     'add'
    'click input[data-action="destroy"]': 'destroy'

  constructor: (params) ->
    super

  active: (params) =>
    @query_preset = params.preset if params.preset
    @render()

  render: =>
    @html @view('directory/search_engine/presets')(@)

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
      @active(QueryPreset.find(id))

  destroy: (e) =>
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @query_preset, =>
        @preset = new QueryPreset()
        @render()

class Index extends App.ExtendedController
  events:
    'click tr.item td:not(.ignore-click)': 'edit'
    'click tr button[name=directory-person-destroy]': 'destroy'
    'click tr button[name=directory-person-change-password]': 'change_password'
    'click button[name=directory-export-to-csv]': 'export_to_csv'

  constructor: (params) ->
    super
    @json_query = $('#directory_json_query').val()
    @query = $.parseJSON(@json_query)

  active: (params) ->
    @render()

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
    @search = new Search
    @edit = new Edit
    @index = new Index
    @append(@search, @edit, @index)

  activate: ->
    super
    QueryPreset.one 'refresh', =>
      qp = QueryPreset.first()
      @search.active(preset: qp)
      @edit.active(preset: qp)
      @index.active(preset: qp)

    SearchAttribute.one 'refresh', =>
      QueryPreset.fetch()

    # Do not use index but searchable method
    SearchAttribute.fetch(url: "#{SearchAttribute.url()}/searchable")
