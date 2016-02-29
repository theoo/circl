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

Person = App.Person
PersonAffair = App.PersonAffair
ProductItem = App.PersonAffairProductsProgram
ProductCategory = App.PersonAffairProductsCategory
ProductProgram = App.ProductProgram
Permissions = App.Permissions

$.fn.product_id = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class PersonAffairProductExtension extends App.ExtendedController

  init_locals: =>
    # Theses locals need to be set when template has been rendered
    @product_field = @el.find("#person_affair_product_search")
    @product_description = @el.find("#person_affair_product_description")
    @parent_field = @el.find("#person_affair_product_parent_search")
    @parent_description = @el.find("#person_affair_product_parent_description")
    @product_id_field = @el.find("input[name=product_id]")
    @program_field = @el.find("#person_affair_product_program_search")
    @program_description = @el.find("#person_affair_product_program_description")
    @program_id_field = @el.find("input[name=program_id]")
    @product_unit_symbol = @el.find("#affair-product-unit")
    @product_category = @el.find("#person_affair_product_category")

  product_selected: (e, ui) =>
    @product_id_field.val ui.item.id

    @program_field.autocomplete source: '/settings/products/' + ui.item.id + '/programs'

    App.Product.one "refresh", =>
      prod = App.Product.find(ui.item.id)
      symbol = I18n.t("product.units." + prod.unit_symbol + ".symbol")
      @product_unit_symbol.html(symbol)
      @product_category.val prod.category

    App.Product.fetch(id: ui.item.id)

    if ui.item.program_key
      @program_field.val ui.item.program_key
      @program_id_field.val ui.item.program_id
      obj = {title: ui.item.program_title, desc: ui.item.program_desc}
      @program_description.html @view('people/affairs/products/_description')(object: obj)

    # Update description
    @product_description.html @view('people/affairs/products/_description')(object: ui.item)

  update_description_on_select: =>

    select_callback_for = (div, ui) =>
      div.html @view('people/affairs/products/_description')(object: ui.item)
      text_field = div.parent().find("input[type='search']")
      hidden_field = div.parent().find("input[type='hidden']")
      hidden_field.attr('value', ui.item.id)
      text_field.attr('value', ui.item.title) if ui.item.title

    @parent_field.autocomplete
      select: (e, ui) => select_callback_for(@parent_description, ui)
    @program_field.autocomplete
      select: (e, ui) => select_callback_for(@program_description, ui)

class New extends PersonAffairProductExtension
  events:
    'submit form': 'submit'
    'click a[name="reset"]': 'reset'

  constructor: ->
    super

  active: (params) =>
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id
      @can = params.can if params.can

    @render()

  render: =>
    @show()
    @product = new ProductItem(quantity: 1, unit_symbol: "?")
    @html @view('people/affairs/products/form')(@)
    @init_locals()

    @product_field.autocomplete select: @product_selected
    @update_description_on_select()

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    ProductItem.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @product.fromForm(e.target)
    @save_with_notifications @product, =>
      @render()
      ProductCategory.fetch()
      ProductItem.fetch()
      PersonAffair.fetch(id: @affair_id)

class Edit extends PersonAffairProductExtension
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=person-affair-product-destroy]': 'destroy'
    'click button[name=reset_value]': 'reset_value'
    'change #person_affair_product_bid_percentage': 'clear_value'
    'change #person_affair_product_quantity': 'clear_value'
    'autocompleteselect #person_affair_product_search': 'clear_value'
    'autocompleteselect #person_affair_product_program_search': 'clear_value'
    'focus input': 'check_replace_value'
    'focus textarea': 'check_replace_value'

  constructor: ->
    super

  active: (params) =>
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id
      @can = params.can if params.can

      # Toggle ids or id so it's easier to know when I'm group editing.
      if params.ids
        @ids = params.ids
      else
        params.ids = undefined

      if params.id
        @id = params.id
      else
        @id = undefined # Clear current id when editing group

    @render()

  render: =>
    return unless @can

    if @id
      @product = ProductItem.find(@id)
    else if @ids
      @product = new ProductItem( unit_symbol: "?")
    else
      return

    @editing_a_group = not @id and @ids
    @html @view('people/affairs/products/form')(@)
    @init_locals()

    if @id
      @product_field.autocomplete select: @product_selected
      @program_field.autocomplete source: '/settings/products/' + @product.product_id + '/programs'
      @update_description_on_select()
    else
      @product_field.prop('disabled', true)
      @program_field.autocomplete source: '/settings/product_programs/search'

    # Enable tooltip for group_edit
    @el.find(".replace_value").tooltip()

    @show()

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    ProductItem.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @product.fromForm(e.target)

    if @ids and not @id

      # Get info from inputs which are checked only
      data = {}
      @el.find(".replace_value:checked").each ->
        $(@).parents(".form-group").find("input:not(.replace_value)").each ->
          i = $(@)
          data[i.prop('name')] = i.val()

      data.ids = @ids

      settings =
        url: ProductItem.url() + "/group_update",
        type: 'POST',
        data: JSON.stringify(data)

      ajax_success = (data, textStatus, jqXHR) =>
        ProductItem.fetch()
        ProductCategory.fetch()
        PersonAffair.fetch(id: @affair_id)
        @hide()

      ajax_error = (xhr, statusText, error) =>
        @render_errors $.parseJSON(xhr.responseText)

      ProductItem.ajax().ajax(settings).success(ajax_success)# .error(ajax_error)

    else
      @save_with_notifications @product, =>
        @hide()
        ProductItem.fetch()
        ProductCategory.fetch()
        PersonAffair.fetch(id: @affair_id)

  destroy: (e) ->
    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      if @ids and not @id

        settings =
          url: ProductItem.url() + "/group_destroy",
          type: 'DELETE',
          data: JSON.stringify({ids: @ids})

        ajax_success = (data, textStatus, jqXHR) =>
          ProductItem.fetch()
          ProductCategory.fetch()
          PersonAffair.fetch(id: @affair_id)
          @hide()

        ajax_error = (xhr, statusText, error) =>
          @render_errors $.parseJSON(xhr.responseText)

        ProductItem.ajax().ajax(settings).success(ajax_success)# .error(ajax_error)

      else
        @destroy_with_notifications @product, =>
          @hide()
          ProductItem.fetch()
          PersonAffair.fetch(id: @affair_id)

  reset_value: (e) ->
    e.preventDefault()
    @el.find("#person_affair_product_value").val @product.computed_value
    @el.find("[name='value_currency']").val @product.computed_value_currency

  clear_value: (e) ->
    e.preventDefault()
    @el.find("#person_affair_product_value").val null

  check_replace_value: (e) ->
    $(e.target).parents(".form-group").find('.replace_value').prop(checked: true)

class Index extends App.ExtendedController
  events:
    'click tr.item td:not(.ignore-click)': 'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=affair_products_csv]': 'csv'
    'click a[name=affair_products_pdf]': 'pdf'
    'click a[name=affair_products_odt]': 'odt'
    'click button[name=affair-product-items-reorder]': 'reorder'
    'click button[name=affair-product-items-group-edit]': 'group_edit'
    'change input[name="select_all"]': 'toggle_checks'
    'change input[type="checkbox"]': 'toggle_check'

  constructor: (params) ->
    super
    ProductItem.bind('refresh', @render)
    ProductCategory.bind('refresh', @render)

  active: (params) ->
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id
      @affair = App.PersonAffair.find(@affair_id) if @affair_id
      @can = params.can if params.can

    @selected = []
    @render()

  render: =>

    @html @view('people/affairs/products/index')(@)

    @el.find(".datatable_wrapper").css(maxHeight: '600px', overflow: 'auto')

    refresh_index = =>
      ProductItem.fetch()

    @el.find('table.datatable')
      .rowReordering(
        sURL: ProductItem.url() + "/change_position"
        sRequestType: "GET"
        iIndexColumn: 0
        fnSuccess: refresh_index)

    first_category = ProductCategory.ordered()[0]
    if first_category
      @el.find("#person_affairs_products_category_global")
        .addClass("active")
      @el.find("#person_affairs_products_nav a[href='#person_affairs_products_category_global']")
        .closest("li")
        .addClass("active")

    nav = @el.find("#person_affairs_products_nav")
    update_category_position = (e) ->
      ul = $(e.target).find("li")
      order = $.map ul, (val, i) ->
        $(val).data("id")

      settings =
        url: ProductCategory.url() + "/update",
        type: 'POST',
        data: {ids: order}

      ajax_success = (data, textStatus, jqXHR) =>
        ProductCategory.fetch()

      # FIXME Add error validation
      Spine.Ajax.queue =>
        $.ajax(settings).success(ajax_success)

    nav.sortable(
      stop: update_category_position
      items: 'li:not(.not-sortable)')

    @toggle_group_edit_button()

    # Scroll to the previous selected element
    tab = $("#person_affairs_products_nav li[data-id='#{@last_category_id}'] a")
    tab.click()
    active_table = @el.find(".tab-pane.active .datatable_wrapper")
    last_item = active_table.find("tr[data-id='#{@last_id}']")
    if last_item.length > 0
      active_table.scrollTop(active_table.scrollTop() + last_item.position().top)

  edit: (e) ->
    @id = $(e.target).product_id()
    @activate_in_list e.target
    @last_id = @id
    @last_category_id = $("#person_affairs_products_nav li.active").data("id")
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

  csv: (e) ->
    e.preventDefault()
    window.location = ProductItem.url() + ".csv?items=#{@selected_as_params()}"

  url_for: (format) ->
    url = ProductItem.url() + ".#{format}?template_id=#{@template_id}"
    url = url + "&items=#{@selected_as_params()}"
    e = @el.find("input[name=export_all]:checked")
    url = url + "&export_all=true" if e.length == 1
    url

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_products_template").val()
    window.location = @url_for('pdf')

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_products_template").val()
    window.location = @url_for('odt')

  reorder: (e) ->
    e.preventDefault()
    settings =
      url: ProductItem.url() + "/reorder",
      type: 'POST'

    ajax_success = (data, textStatus, jqXHR) =>
      ProductItem.fetch()

    # FIXME Add error validation
    Spine.Ajax.queue =>
      $.ajax(settings).success(ajax_success)

  toggle_check: (e) ->
    id = $(e.target).product_id()
    status = $(e.target).prop("checked")

    checkboxes = @el.find("table").each (index, table) ->
      datatable = $(table).dataTable()
      $(datatable.fnGetNodes()).find("input[type='checkbox']").each (index, c) ->
        if $(c).product_id() == id
          $(c).prop('checked', status)
      datatable.fnDraw()

    @update_selected_index(id, status)
    @toggle_group_edit_button()

  toggle_checks: (e) ->
    status = $(e.target).is(":checked")

    current_table = $(e.target).closest("table")
    current_datatable = current_table.dataTable()
    current_ids = $(current_datatable.fnGetNodes()).map (index, c) -> $(c).product_id()

    @el.find("table").each (index, table) =>
      datatable = $(table).dataTable()

      for id in current_ids
        $(datatable.fnGetNodes()).siblings("tr[data-id=#{id}]").each ->
          $(@).find("input[type='checkbox']").prop('checked', status)

        @update_selected_index(id, status)

      datatable.fnDraw()
    @toggle_group_edit_button()

  update_selected_index: (id, status) ->
    if status and id
      @selected.push id unless @selected.indexOf(id) >= 0
    else
      @selected = _.without(@selected, id)

  group_edit: (e) ->
    e.preventDefault()
    @trigger 'group_edit', @selected

  selected_as_params: ->
    JSON.stringify @selected

  toggle_group_edit_button: ->
    btn = @el.find("button[name=affair-product-items-group-edit]")
    if @selected?.length > 0
      btn.attr(disabled: false)
    else
      btn.attr(disabled: true)

  is_checked: (id) ->
    @selected?.indexOf(id) >= 0

class App.PersonAffairProducts extends Spine.Controller
  className: 'products'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'group_edit', (ids) =>
      @edit.active person_id: @person_id, affair_id: @affair_id, ids: ids

    @index.bind 'edit', (id) =>
      @edit.active person_id: @person_id, affair_id: @affair_id, id: id

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    App.Product.one 'count_fetched', =>
      ProductProgram.one 'names_fetched', =>
        Permissions.get { person_id: @person_id, can: { invoice: ['create', 'update'] }}, (data) =>
          @new.active { person_id: @person_id, affair_id: @affair_id, can: data }
          @index.active {can: data, affair_id: @affair_id, person_id: @person_id}
          @edit.active {can: data}
          @edit.hide()

      ProductProgram.fetch_names()

    App.Product.fetch_count()
