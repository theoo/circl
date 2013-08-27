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

Affair = App.Affair

$.fn.affair = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Affair.find(elementID)

class Index extends App.ExtendedController
  events:
    'affair-edit':      'edit'

  constructor: (params) ->
    super

  render: =>
    @html @view('admin/affairs/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    id = $(e.target).attr('data-id')
    Affair.one 'refresh', =>
      affair = Affair.find(id)
      window.location = "/people/#{affair.owner_id}?folding=person_affairs"
    Affair.fetch(id: id)

class App.AdminAffairs extends Spine.Controller
  className: 'affairs'

  constructor: (params) ->
    super

    @index = new Index
    @append(@index)

  activate: ->
    super
    @index.render()
