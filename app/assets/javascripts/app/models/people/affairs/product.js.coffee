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

class App.PersonAffairProductVariant extends Spine.Model

  @configure 'PersonAffairProductVariant', "parent_id", "affair_id", "variant_id", "program_id",
    "parent_key", "affair_title", "variant_key", "program_key",
    "position", "quantity", "created_at", "updated_at", 'description', 'key', 'value'

  @extend Spine.Model.Ajax

  @url: -> undefined

  constructor: ->
    super
