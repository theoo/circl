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

class App.Product extends Spine.Model

  @configure 'Product', "id", "provider_id", "after_sale_id", "key", "title",
              "description", "has_accessories", "archive", "variants", "category",
              "unit_symbol", "price_to_unit_rate"

  @extend Spine.Model.Ajax
  @extend Spine.Extensions.RemoteCount

  @url: -> "/settings/products"

  constructor: ->
    super
