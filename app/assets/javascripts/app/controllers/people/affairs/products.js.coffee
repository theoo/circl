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
PersonAffairProductsProgram = App.PersonAffairProductsProgram
ProductProgram = App.ProductProgram
Permissions = App.Permissions

$.fn.product = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class PersonAffairProductExtention extends App.ExtendedController

  init_locals: =>
    # Theses locals need to be set when template has been rendered
    @product_field = @el.find("#person_affair_product_search")
    @product_id_field = @el.find("input[name=product_id]")
    @program_field = @el.find("#person_affair_product_program_search")
    @program_id_field = @el.find("input[name=program_id]")
    @product_unit_symbol = @el.find("#affair-product-unit")

  product_selected: (e, ui) =>
    @product_id_field.val ui.item.id

    @program_field.autocomplete source: '/settings/products/' + ui.item.id + '/programs'

    App.Product.one "refresh", =>
      prod = App.Product.find(ui.item.id)
      symbol = I18n.t("product.units.#{prod.unit_symbol}.symbol")
      @product_unit_symbol.html(symbol)

    App.Product.fetch(id: ui.item.id)

    if ui.item.program_key
      @program_field.val ui.item.program_key
      @program_id_field.val ui.item.program_id

class New extends PersonAffairProductExtention
  events:
    'submit form': 'submit'

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
    @product = new PersonAffairProductsProgram(quantity: 1, unit_symbol: "?")
    @html @view('people/affairs/products/form')(@)
    @init_locals()

    @product_field.autocomplete select: @product_selected

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairProductsProgram.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @product.fromForm(e.target)
    @save_with_notifications @product, =>
      @render()
      PersonAffairProductsProgram.refresh([], clear: true)
      PersonAffairProductsProgram.fetch()
      PersonAffair.fetch(id: @affair_id)

class Edit extends PersonAffairProductExtention
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=person-affair-product-destroy]': 'destroy'

  constructor: ->
    super

  active: (params) =>
    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id
      @can = params.can if params.can
      @id = params.id if params.id

    @render()

  render: =>
    return unless PersonAffairProductsProgram.exists(@id) && @can
    @product = PersonAffairProductsProgram.find(@id)

    @html @view('people/affairs/products/form')(@)
    @init_locals()

    @product_field.autocomplete select: @product_selected
    @program_field.autocomplete source: '/settings/products/' + @product.product_id + '/programs'

    @show()
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairProductsProgram.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @product.fromForm(e.target)
    @save_with_notifications @product, =>
      @hide()
      PersonAffairProductsProgram.refresh([], clear: true)
      PersonAffairProductsProgram.fetch()
      PersonAffair.fetch(id: @affair_id)

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @product, =>
        @hide()
        PersonAffairProductsProgram.refresh([], clear: true)
        PersonAffairProductsProgram.fetch()
        PersonAffair.fetch(id: @affair_id)

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=affair-products-csv]': 'csv'
    'click a[name=affair-products-pdf]': 'pdf'
    'click a[name=affair-products-odt]': 'odt'
    'click a[name=affair-products-preview]': 'preview'

  constructor: (params) ->
    super
    PersonAffairProductsProgram.bind('refresh', @render)

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    @html @view('people/affairs/products/index')(@)

    refresh_index = =>
      PersonAffairProductsProgram.refresh([], clear: true)
      PersonAffairProductsProgram.fetch()

    @el.find('table.datatable')
      .rowReordering(
        sURL: PersonAffairProductsProgram.url() + "/change_order"
        sRequestType: "GET"
        iIndexColumn: 0
        fnSuccess: refresh_index)

  edit: (e) ->
    @id = $(e.target).product()
    @activate_in_list e.target
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

  csv: (e) ->
    e.preventDefault()
    window.location = PersonAffairProductsProgram.url() + ".csv"

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_products_template").val()
    window.location = PersonAffairProductsProgram.url() + ".pdf?template_id=#{@template_id}"

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_products_template").val()
    window.location = PersonAffairProductsProgram.url() + ".odt?template_id=#{@template_id}"

  preview: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_products_template").val()

    win = $("<div class='modal fade' id='affair-products-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.preview')

    # Insert iframe to content
    iframe = $("<iframe src='" +
                "#{PersonAffairProductsProgram.url()}.html?template_id=#{@template_id}" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    win.find('.modal-body').html iframe

    # Adapt width to A4
    win.find('.modal-dialog').css(width: 900)

    # Add preview in new tab button
    btn = "<button type='button' name='affair-products-preview-in-new-tab' class='btn btn-default'>"
    btn += I18n.t('affair.views.actions.preview_in_new_tab')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonAffairProductsProgram.url()}.html?template_id=#{@template_id}", "affair_products_preview"

    win.modal('show')

class App.PersonAffairProducts extends Spine.Controller
  className: 'products'

  constructor: (params) ->
    super

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

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
          @index.active {can: data}
          @edit.active {can: data}
          @edit.hide()

      ProductProgram.fetch_names()

    App.Product.fetch_count()
