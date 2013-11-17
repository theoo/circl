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
PersonAffairProductVariant = App.PersonAffairProductVariant
ProductProgram = App.ProductProgram
Permissions = App.Permissions

$.fn.product = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class PersonAffairProductExtention extends App.ExtendedController

  render: =>
    @product_field = @el.find("#person_affair_product_search")
    @product_id_field = @el.find("input[name=variant_id]")
    @program_field = @el.find("#person_affair_product_program_search")
    @program_id_field = @el.find("input[name=program_id]")

    ### Callbacks ###
    # product is cleared
    @product_field.on 'keyup search', (e) =>
      # if $(e.target).val() == ''

    # product is selected
    @product_field.autocomplete('option', 'select', (e, ui) =>
      @product_id_field.val ui.item.id
      # set program search url
      @program_field.autocomplete({source: '/settings/products/' + ui.item.id + '/programs' })
    )


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
    super
    @show()
    @product = new PersonAffairProductVariant(quantity: 1)
    @html @view('people/affairs/products/form')(@)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairProductVariant.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @product.fromForm(e.target)
    @save_with_notifications @product, @render

class Edit extends PersonAffairProductExtention
  events:
    'submit form': 'submit'
    'click button[name=person-affair-product-destroy]': 'destroy'

  constructor: ->
    super

  active: (params) =>
    @can = params.can if params.can
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonAffairProductVariant.exists(@id) && @can
    super

    @product = PersonAffairProductVariant.find(@id)

    @show()
    @html @view('people/affairs/products/form')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairProductVariant.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @product.fromForm(e.target)
    @save_with_notifications @product, @hide

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @product, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=products-csv]': 'export_csv'
    'click a[name=products-pdf]': 'export_pdf'

  constructor: (params) ->
    super
    PersonAffairProductVariant.bind('refresh', @render)

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    @html @view('people/affairs/products/index')(@)

  edit: (e) ->
    @id = $(e.target).product()
    @activate_in_list e.target
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

  export_csv: (e) ->
    e.preventDefault()
    window.location = PersonAffairProductVariant.url() + ".csv"

  export_pdf: (e) ->
    e.preventDefault()
    window.location = PersonAffairProductVariant.url() + ".pdf"

class App.PersonAffairProducts extends Spine.Controller
  className: 'products'

  constructor: (params) ->
    super

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
