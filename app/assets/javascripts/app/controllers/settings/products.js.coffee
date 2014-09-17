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

Product = App.Product
ProductProgram = App.ProductProgram

$.fn.product = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class VariantsController extends App.ExtendedController

  remove_variant: (e) ->
    current_row = $(e.target).closest("tr")
    current_row.remove()

  add_variant: (e) ->
    template = @el.find('tr[data-name="variant_template"]')
    new_row = template.clone()
    # theses attributes belongs to template only
    new_row.removeAttr('data-name')
    new_row.removeClass('hidden')
    # this class make it selected on submit
    new_row.addClass('item')

    variant_add = @el.find('tr[data-name="variant_add"]')
    variant_add.before(new_row)

    Ui.load_ui(new_row)

  make_item_removable: (e) ->
    @el.find('table.category tr.item').each ->
      $(@).find('td:last input[type="button"]').show()

    # hide the first remove button
    @el.find('table.category tr.item:first td:last input[type="button"]').hide()

  fetch_items: (e) ->
    values = []
    @el.find('table.table tr.item:not(.hidden)').each (i, tr) ->
      tr = $(tr)
      val =
        id: tr.find("input[name='variants[][id]']").val()
        title: tr.find("input[name='variants[][title]']").val()
        description: tr.find("textarea[name='variants[][description]']").val()
        buying_price: tr.find("input[name='variants[][buying_price]']").val()
        buying_price_currency: tr.find("select[name='variants[][buying_price_currency]']").val()
        selling_price: tr.find("input[name='variants[][selling_price]']").val()
        selling_price_currency: tr.find("select[name='variants[][selling_price_currency]']").val()
        art: tr.find("input[name='variants[][art]']").val()
        art_currency: tr.find("select[name='variants[][art_currency]']").val()
        program_group: tr.find("select[name='variants[][program_group]'] option:selected").val()

      values.push val

    return values

class New extends VariantsController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name="remove_variant"]':  'remove_variant'
    'click button[name="add_variant"]':     'add_variant'
    'click a[name="reset"]': 'reset'

  constructor: ->
    super
    ProductProgram.bind 'names_fetched', @render

  active: (params) =>
    @render()

  render: =>
    @product = new Product(archive: false, has_accessories: true)
    @html @view('settings/products/form')(@)
    @make_item_removable()
    @show()

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    data.variants = @fetch_items()
    @product.load(data)
    @product.archive = data.archive?
    @product.has_accessories = data.has_accessories?
    @save_with_notifications @product, @render

class Edit extends VariantsController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=settings-product-destroy]': 'destroy'
    'click button[name="remove_variant"]':  'remove_variant'
    'click button[name="add_variant"]':     'add_variant'

  constructor: ->
    super
    # Won't reload program names if updated
    # ProductProgram.bind 'names_fetched', @render

  active: (params) =>
    @id = params.id if params.id
    @product = Product.find(@id)
    @render()

  render: =>
    @html @view('settings/products/form')(@)
    @make_item_removable()
    @show()

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    data.variants = @fetch_items()
    @product.load(data)
    @product.archive = data.archive?
    @product.has_accessories = data.has_accessories?
    @save_with_notifications @product

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @product, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    Product.bind('refresh', @render)

  render: =>
    @html @view('settings/products/index')(@)

  edit: (e) ->
    e.preventDefault()

    @id = $(e.target).product()
    Product.one 'refresh', =>
      @activate_in_list e.target
      @trigger 'edit', @id

    Product.fetch(id: @id)

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

class App.SettingsProducts extends Spine.Controller
  className: 'products'

  constructor: (params) ->
    super

    App.ProductProgram.bind 'refresh', => @activate()

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super

    App.ProductProgram.one 'count_fetched', =>
      ProductProgram.one 'names_fetched', =>
        # Product.fetch() # Datatable takes care of this
        @index.render()
        @new.active()

      ProductProgram.fetch_names()

    App.ProductProgram.fetch_count()
