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

class App.QueryPreset extends Spine.Model

  @configure 'QueryPreset', 'id', 'name', 'query'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/directory/query_presets"

  constructor: (params) ->
    super
    # Defaults and required fields
    @selected_attributes = if params?.selected_attributes then params.selected_attributes else []
    @attributes_order = if params?.attributes_order then params.attributes_order else []
    @query = if params?.query then params.query else ""

  to_params: ->
    "query=#{encodeURIComponent(JSON.stringify(@query))}"
