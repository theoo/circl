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

class App.PersonTask extends Spine.Model

  @configure 'PersonTask', 'affair_id', 'created_at', 'description',
    'duration', 'executer_id', 'id', 'salary_id', 'start_date', 'task_type_id',
    'updated_at', 'value_currency', 'owner_name', 'executer_name',
    'value', 'duration_in_words', 'affair_title'

  @extend Spine.Model.Ajax

  # URL is defined when loading an affair
  @url: -> undefined

  constructor: ->
    super
