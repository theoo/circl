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

class App.PersonAffair extends Spine.Model

  @configure 'PersonAffair', 'owner_id', 'owner_name', 'buyer_id', 'buyer_name', 'estimate',
             'receiver_id', 'receiver_name', 'parent_id', 'footer', 'seller_id', 'title',
             'description', 'value', 'value_currency', 'created_at', 'custom_value_with_taxes',
             'conditions', 'condition_id', 'affairs_stakeholders', 'unbillable', 'copy_parent',
             'notes'

  @extend Spine.Model.Ajax
  @extend Spine.Extensions.RemoteCount

  constructor: ->
    super
