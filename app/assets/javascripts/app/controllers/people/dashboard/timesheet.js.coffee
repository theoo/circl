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

PersonTask = App.PersonTask

$.fn.task = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonTask.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'slide': 'slide'
    'keyup #task_duration': 'duration_change'

  constructor: (params) ->
    super

  render: =>
    @task = new PersonTask
    @html @view('people/tasks/form')(@)
    @el.find(".timeline")
      .slider(min: 0, max: 23, step: 0.25, tooltip: 'hide')

  slide: (e) ->
    # duration is in minutes
    duration = (e.value[1] - e.value[0]) * 60
    $("#task_duration").val duration
    @update_summary(e.value)

  duration_change: (e) ->
    duration = $(e.target).val()
    slider = @el.find(".timeline").data('slider')

    values = slider.getValue()
    # I have to write it. JS sucks.
    values[1] = values[0] + parseFloat((duration / 60).toPrecision(duration.toString().length))
    slider.setValue(values)

    @update_summary(values)

  update_summary: (values) ->
    # funktional yeah
    base100_to_base60 = (f) =>
      h = Math.floor f
      m = parseInt((60 * (f - h)).toPrecision(2))
      h.pad(2) + ":" + m.pad(2)

    @el.find('.summary .from').html base100_to_base60(values[0])
    @el.find('.summary .to').html base100_to_base60(values[1])

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @task.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'task-destroy': 'destroy'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @task = PersonTask.find(@id)
    @render()

  render: =>
    @html @view('people/tasks/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @task.fromForm(e.target), @hide

  destroy: (e) ->
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications(@task)

class Index extends App.ExtendedController
  events:
    'task-edit': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    PersonTask.bind('refresh', @render)

  active: ->
    if params and params.task_id
      @task = PersonTask.find(params.task_id)
    @render()

  render: =>
    @html @view('people/tasks/index')(@)

  edit: (e) ->
    @task = $(e.target).task()
    @trigger 'edit', task.id

  table_redraw: =>
    if @task
      target = $(@el).find("tr[data-id=#{@task.id}]")
    @activate_in_list(target)

class App.DashboardTimesheet extends Spine.Controller
  className: 'tasks'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonTask.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/tasks"

    @index = new Index
    @edit = new Edit
    @new = new New
    @append(@new, @edit, @index)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    PersonTask.fetch()
    @new.render()
