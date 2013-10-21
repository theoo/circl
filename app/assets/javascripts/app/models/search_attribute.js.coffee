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

class App.SearchAttribute extends Spine.Model

  @configure 'SearchAttribute', 'model', 'name', 'indexing', 'mapping', 'group', 'searchable', 'orderable'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/settings/search_attributes"

  constructor: ->
    super

  @orderable: =>
    sa = []
    for attr in @all()
      sa.push(attr) if attr.orderable
    sa

  @searchable: ->
    sa = []
    for attr in @all()
      sa.push(attr) if attr.searchable
    sa

  @attributes_for: (group) ->
    sa = []
    for attr in @all()
      sa.push(attr) if attr.group == group
    sa

  @groups: ->
    _.uniq(@all().map((sa) -> sa.group))

  validate: ->
    e = new App.ErrorsList

#    unless @model
#      e.add model: I18n.t('activerecord.errors.messages.blank')

#    unless @name
#      e.add name: I18n.t('activerecord.errors.messages.blank')

#    unless @indexing
#      e.add indexing: I18n.t('activerecord.errors.messages.blank')

#    unless @mapping
#      e.add mapping: I18n.t('activerecord.errors.messages.blank')

#    if typeof(@mapping) == 'string'
#      try
#        @mapping = JSON.parse(@mapping)
#      catch error
#        e.add mapping: I18n.t('search_attribute.errors.not_json')

    return e unless e.is_empty()
