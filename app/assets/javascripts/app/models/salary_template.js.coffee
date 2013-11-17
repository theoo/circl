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

class App.SalaryTemplate extends Spine.Model

  @configure 'SalaryTemplate', 'title', 'language_id', 'html', 'thumb_url'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/settings/salary_templates"

  constructor: ->
    super

  validate: ->
    e = new App.ErrorsList
    return e unless e.is_empty()

  @fetch_count: ->
    get_callback = (data) =>
      @_count = data
      @trigger "count_fetched"

    $.get(@url() + "/count", get_callback, 'json')

  @count: ->
    @_count.count if @_count