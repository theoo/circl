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
TaskType   = App.TaskType

$.fn.task = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonTask.find(elementID)

class New extends App.TimesheetExtention

  events:
    'submit form': 'submit'
    'slide': 'on_slide_change'
    'keyup #task_duration': 'on_duration_change'
    'focus .time': 'select_content'
    'blur .time': 'on_time_change'
    'change select[name=task_type_id]': 'update_task_type_description'

  constructor: (params) ->
    super

  render: =>
    @task = new PersonTask

    @task.start_date = (new Date).to_view()
    @task.start_time = '09:00'
    @task.end_time = '18:00'
    @task.duration = 9 * 60

    super

    @disable_affair_selection()
    @disable_timesheet()
    @disable_submit()

  submit: (e) ->
    e.preventDefault()
    @task.fromForm(e.target)
    @task.start_date = @repack_date_time(@task.start_date)
    @save_with_notifications @task, @render

class Edit extends App.TimesheetExtention

  events:
    'submit form': 'submit'
    'click button[name=task-destroy]': 'destroy'
    'slide': 'on_slide_change'
    'keyup #task_duration': 'on_duration_change'
    'focus .time': 'select_content'
    'blur .time': 'on_time_change'
    'click button[name=reset_value]': 'reset_value'
    'change select[name=task_type_id]': 'update_task_type_description'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @task = PersonTask.find(@id)
    @render()

  render: =>
    # Unpack date/time
    dt = @task.start_date.split(" ")
    @task.start_date = dt[0]
    @task.start_time = dt[1]

    st = @time_to_float(dt[1])
    @task.end_time = @float_to_time(st + (@task.duration / 60))

    super

  submit: (e) ->
    e.preventDefault()
    @task.fromForm(e.target)
    @task.start_date = @repack_date_time(@task.start_date)
    @save_with_notifications @task, @hide

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications @task, @hide

  reset_value: () ->
    e.preventDefault()
    @value_field.val @task.computed_value

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
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
    e.preventDefault()
    @task = $(e.target).task()
    @activate_in_list(e.target)
    @trigger 'edit', @task.id

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
      @edit.show()

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super

    TaskType.one 'refresh', =>
      PersonTask.fetch()
      @new.render()

    TaskType.fetch()

