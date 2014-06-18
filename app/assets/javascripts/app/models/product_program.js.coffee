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

class App.ProductProgram extends Spine.Model

  @configure 'ProductProgram', "id", "key", "title", "description", "color",
              "program_group", "archive"

  @extend Spine.Model.Ajax
  @extend Spine.Extensions.RemoteCount

  @url: ->
    "#{Spine.Model.host}/settings/product_programs"

  constructor: (params) ->
    super(params)

  @fetch_names: ->
    get_callback = (data) =>
      @program_names = data
      @trigger "names_fetched"

    $.get(ProductProgram.url() + "/program_groups", get_callback, 'json')

  @names: ->
    @program_names.sort() if @program_names
