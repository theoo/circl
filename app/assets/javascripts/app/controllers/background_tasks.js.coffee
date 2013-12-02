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

BackgroundTask = App.BackgroundTask

$.fn.background_task = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  BackgroundTask.find(elementID)

class Index extends App.ExtendedController
  events:
    'click button[name=background-task-destroy]': 'destroy'

  constructor: (params) ->
    super
    BackgroundTask.bind('refresh', @render)

  render: =>
    @html @view('background_tasks/index')(@)

  destroy: (e) ->
    e.preventDefault()
    background_task = $(e.target).background_task()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications(background_task)

  activate: (params) ->
    @can = params.can if params.can

class App.DashboardBackgroundTasks extends Spine.Controller
  className: 'background_tasks'

  constructor: (params) ->
    super

    @person_id = params.person_id

    @index = new Index()
    @append @index

  activate: (params) ->
    BackgroundTask.fetch()

    App.Permissions.get {
      person_id: @person_id,
      can: {
        background_task: ['read', 'manage']
      }
      }, (data) => @index.activate(can: data)

