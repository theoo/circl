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

class Counter extends App.ExtendedController
  events:
    'click a': 'list'

  constructor: (params) ->
    super
    BackgroundTask.bind('refresh', @check_for_update)
    setInterval(@fetch_records, App.BackgroundTaskRefreshInterval);

  fetch_records: ->
    get_callback = (data) =>
      @records = data

    $.get(BackgroundTask.url(), get_callback, 'json')

    if @records
      BackgroundTask.refresh(@records, clear: true)

  check_for_update: =>
    previous_count = @el.find('a').data('count')
    count = BackgroundTask.all().length

    if previous_count != count
      @render()
      BackgroundTask.trigger('refresh-list')

  render: =>
    count = BackgroundTask.all().length
    title = count + " " + I18n.t("background_task.views.tasks_pending")
    button = $("<a href='#' class='button' data-count='#{count}'>&nbsp;#{title}&nbsp;</a>")
    @el.html(button)

    Ui.load_ui(@el)

    if count == 0
      button.button( "option", "disabled", true );
    else
      button.button( "option", "disabled", false );

    # button.effect('highlight', {color: "#E2E4FF"})

  list: (e) ->
    e.preventDefault()
    @trigger 'dialog'


class App.BackgroundTasks extends Spine.Controller
  className: 'background_tasks'

  constructor: (params) ->
    super

    @counter = new Counter

    window = Ui.stack_window('background_tasks_list', {width: 800})
    @index = new Index({el: window})
    # @index_window = $(window).modal({title: I18n.t('background_task.views.background_tasks_list_title')})
    @index_window = $(window).modal('hide')

    @append(@counter)
    BackgroundTask.fetch()

    @counter.bind 'dialog', =>
      @index_window.modal('show')
      @index.activate({})

    App.Permissions.get { person_id: params.person_id, can: { background_task: ['read', 'manage'] }}, (data) => @index.activate(can: data)


class Index extends App.ExtendedController
  events:
    'background-task-destroy':      'destroy'

  constructor: (params) ->
    super
    BackgroundTask.bind('refresh-list', @render)

  render: =>
    @html @view('background_tasks/index')(@)
    Ui.load_ui(@el)

  destroy: (e) ->
    background_task = $(e.target).background_task()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications(background_task)

  activate: (params) ->
    @can = params.can if params.can
