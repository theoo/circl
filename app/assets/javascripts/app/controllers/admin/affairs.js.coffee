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

Affair = App.Affair

class Index extends App.ExtendedController
  events:
    'click tbody tr.item>td:not(.ignore-click)':    'edit'
    'click button[name="admin-affairs-documents"]': 'documents'
    'datatable_redraw':                             'table_redraw'
    'click a[name=admin-affairs-archive]':          'group_edit'
    'click a[name=admin-affairs-unarchive]':        'group_edit'
    'click a[name=admin-affairs-billable]':         'group_edit'
    'click a[name=admin-affairs-unbillable]':       'group_edit'
    'click [name=add-to-selection]':                'filter_selection'
    'click [name=remove-from-selection]':           'filter_selection'
    'change tbody input[type="checkbox"]':          'toggle_check'
    'change thead input[name="selected_filter"]':   'filter_selected'
    'click a[name="admin_affairs_pdf"]':            'pdf'
    'click a[name="admin_affairs_odt"]':            'odt'
    'click a[name="admin_affairs_csv"]':            'csv'
    'click a[name="admin_affairs_txt"]':            'txt'

  constructor: (params) ->
    super
    Affair.bind 'refresh', @render
    @selected_ids = gon.selected_admin_affairs

  render: =>
    @html @view('admin/affairs/index')(@)

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    window.location = "/admin/affairs/#{id}"

  table_redraw: =>
    # Unbind checkbox in header (so it doesn't try to sort)
    @el.find('thead>tr>th.ignore-sort').each (index, el) ->
      $(el).unbind 'click'

    # Add class and checkbox to each item
    @el.find('tbody>tr.item>td:last-child').each (index, el) ->
      $(el).addClass('number ignore-click')
      $(el).html "<input type='checkbox'>"
      # $(el).unbind 'click'

    # Rechecked selected items
    $(@selected_ids).each (index, item) =>
      @el.find("tr[data-id=#{item}] input[type='checkbox']").attr(checked: true)

    @update_selected_count()
    @toggle_group_actions_menu()

  url_for: (format) ->
    @template_id = @el.find("#admin_affairs_template").val()
    # Base64 encoded
    order_by = @el.find("table.datatable").dataTable().fnSettings().aaSorting.join(",")
    Affair.url() + ".#{format}?template_id=#{@template_id}&order_by=#{order_by}"

  csv: (e) ->
    e.preventDefault()
    window.location = @url_for('csv')

  pdf: (e) ->
    e.preventDefault()
    window.location = @url_for('pdf')

  odt: (e) ->
    e.preventDefault()
    window.location = @url_for('odt')

  txt: (e) ->
    e.preventDefault()
    window.location = @url_for('txt')

  toggle_check: (e) =>
    e.preventDefault()
    id = $(e.target).creditor_id()

    if $(e.target).is(":checked")
      path = "check_items"
    else
      path = "uncheck_items"

    $.post(Affair.url() + "/#{path}", {id: id})
      .success (response) =>
        @selected_ids = response
        @update_selected_count()
        @toggle_group_actions_menu()

  filter_selection: (e) =>
    e.preventDefault()
    action = $(e.target).closest('button').attr('name')
    footer = $(e.target).closest('.panel-footer')
    form_data = {}
    form_data['date_field'] = footer.find("[name=date_field]").val()
    form_data['group']      = footer.find("[name=filter]").val()
    form_data['from']       = footer.find("[name=select-from]").val()
    form_data['to']         = footer.find("[name=select-to]").val()
    form_data['sSearch']    = $(e.target).closest('.panel').find(".dataTables_wrapper input").val()

    if action == 'remove-from-selection'
      path = "/uncheck_items"
    else
      path = "/check_items"

    @disable_panel

    $.post(Affair.url() + path, form_data)
      .success (response) =>
        @selected_ids = response
        @reload_table()
        @update_selected_count()
        @enable_panel

  filter_selected: (e) =>
    e.preventDefault()

    filter_field_value = @el.find(".dataTables_filter input[type='text']").val()
    dt = @el.find("table.datatable").dataTable()
    if $(e.target).is(":checked")
      dt.fnFilter("SELECTED #{filter_field_value}")
    else
      dt.fnFilter(filter_field_value.replace("SELECTED", "").trim())

  reload_table: ->
    table = @el.find("table.datatable")
    datatable = table.dataTable()
    datatable.fnDraw()

  group_edit: (e) ->
    e.preventDefault()
    action = $(e.target).closest('a').attr('name')

    form_data = {}
    switch action
      when 'admin-affairs-archive'
        form_data['archive'] = true
      when 'admin-affairs-unarchive'
        form_data['archive'] = false
      when 'admin-affairs-unbillable'
        form_data['unbillable'] = true
      when 'admin-affairs-billable'
        form_data['unbillable'] = false

    @disable_panel

    $.post(Affair.url() + "/archive_items", form_data)
      .success (response) =>
        @reload_table()
        @enable_panel

  toggle_group_actions_menu: ->
    btn = @el.find("button[name=admin-affairs-group-actions]")
    if @selected_ids?.length > 0
      btn.attr(disabled: false)
    else
      btn.attr(disabled: true)

  update_selected_count: ->
    box = @el.find("#admin_affairs_select_count")
    if @selected_ids?.length > 0
      box.html(I18n.t("common.item_selected", {count: @selected_ids.length}))
    else
      box.html("")


class App.AdminAffairs extends Spine.Controller
  className: 'affairs'

  constructor: (params) ->
    super

    @index = new Index
    @append(@index)

  activate: ->
    super
    @index.render()
