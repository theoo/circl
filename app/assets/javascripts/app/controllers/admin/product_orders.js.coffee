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

ProductItem = App.ProductOrder

class Index extends App.ExtendedController
  events:
    'click tr.item': 'show'
    'click button[name="admin-product_orders-documents"]':  'documents'

  constructor: (params) ->
    super
    ProductItem.bind 'refresh', @render

  render: =>
    @html @view('admin/product_orders/index')(@)

  show: (e) ->
    e.preventDefault()
    console.log "TODO"
    # id = $(e.target).parents('[data-id]').data('id')
    # ProductItem.one 'refresh', =>
    #   product_item = ProductItem.find(id)
    #   window.location = "/admin/product_orders/#{product_item.id}"
    # ProductItem.fetch(id: id)

#   documents: (e) ->
#     e.preventDefault()

#     win = $("<div class='modal fade' id='admin-product-orders-documents-modal' tabindex='-1' role='dialog' />")
#     # render partial to modal
#     modal = JST["app/views/helpers/modal"]()
#     win.append modal
#     win.modal(keyboard: true, show: false)

#     controller = new ProductOrdersDocumentsMachine({el: win.find('.modal-content')})
#     win.modal('show')
#     controller.activate()

# class ProductOrdersDocumentsMachine extends App.ExtendedController
#   events:
#     'submit form': 'validate'
#     'change #admin_product_items_document_export_format': 'format_changed'

#   constructor: (params) ->
#     super
#     @content = params.content

#   activate: (params)->
#     @format = 'csv' # default format
#     @form_url = App.ProductOrder.url()

#     @template_class = 'ProductOrder'
#     App.ProductOrder.one 'statuses_fetched', =>
#       @render()
#     App.ProductOrder.fetch_statuses()

#   render: =>
#     @html @view('admin/product_orders/documents')(@)

#   validate: (e) ->
#     errors = new App.ErrorsList

#     if @el.find("#admin_product_items_document_export_format").val() != 'csv'
#       unless @el.find("#admin_product_items_document_export_template").val()
#         errors.add ['generic_template_id', I18n.t("activerecord.errors.messages.blank")].to_property()

#     if errors.is_empty()
#       # @render_success() # do nothing...
#     else
#       e.preventDefault()
#       @render_errors(errors.errors)

#   format_changed: (e) ->
#     @format = $(e.target).val()
#     @el.find("form").attr('action', @form_url + "." + @format)

class App.AdminProductOrders extends Spine.Controller
  className: 'product_orders'

  constructor: (params) ->
    super

    @index = new Index
    @append(@index)

  activate: ->
    super
    @index.render()
