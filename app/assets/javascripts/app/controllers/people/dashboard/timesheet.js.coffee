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

class TimesheetController extends App.ExtendedController

  constructor: ->
    super

  render: =>
    @html @view('people/tasks/form')(@)

    ### Field variables ###
    @owner_field = @el.find("input[name='owner']")
    @owner_id_field = @el.find("input[name='owner_id']")
    @affair_field = @el.find("input[name='affair']")
    @affair_id_field = @el.find("input[name='affair_id']")

    @slider_div = @el.find(".timesheet_timeline")

    @date_field = @el.find("input[name='start_date']")
    @start_field = @el.find("input[name='start_time']")
    @end_field = @el.find("input[name='end_time']")
    @duration_field = @el.find("input[name='duration']")
    @value_field = @el.find("input[name='value']")
    @task_type_field = @el.find("select[name='task_type_id']")
    @description_field = @el.find("textarea[name='description']")

    @submit_button = @el.find('button[type=submit]')

    ### Callbacks ###
    # client is cleared
    @owner_field.on 'keyup search', (e) =>
      if $(e.target).val() == ''
        @disable_affair_selection()
        @disable_timesheet()
        @disable_submit()

    # client is selected
    @owner_field.autocomplete('option', 'select', (e, ui) =>
      @owner_id_field.val ui.item.id
      # set affairs search url
      @affair_field.autocomplete({source: '/people/' + ui.item.id + '/affairs/search'})
      @enable_affair_selection()
    )

    # affair is cleared
    @affair_field.on 'keyup search', (e) =>
      if $(e.target).val() == ''
        @disable_timesheet()
        @disable_submit()

    # affair is selected
    @affair_field.autocomplete('option', 'select', (e, ui) =>
      @affair_id_field.val ui.item.id
      @enable_submit()
      @enable_timesheet()
    )

    ### Load slider ###
    @slider_div
      .slider(min: 0, max: 23.75, step: 0.25, tooltip: 'hide')
    @el.find(".slider").width("100%")

  disable_affair_selection: ->
    @affair_field.val("")
    @affair_id_field.val(null)
    @affair_field.prop('disabled', true)

  disable_timesheet: ->
    $("#timesheet").prop('disabled', true)
    # @date_field.prop('disabled', true)
    # @start_field.prop('disabled', true)
    # @end_field.prop('disabled', true)
    # @duration_field.prop('disabled', true)
    # @value_field.prop('disabled', true)
    # @task_type_field.prop('disabled', true)
    # @description_field.prop('disabled', true)

  disable_submit: ->
    @submit_button.addClass('disabled')

  enable_affair_selection: ->
    @affair_field.removeAttr('disabled')

  enable_timesheet: ->
    $("#timesheet").removeAttr('disabled')
    # @date_field.removeAttr('disabled')
    # @start_field.removeAttr('disabled')
    # @end_field.removeAttr('disabled')
    # @duration_field.removeAttr('disabled')
    # @value_field.removeAttr('disabled')
    # @task_type_field.removeAttr('disabled')
    # @description_field.removeAttr('disabled')

  enable_submit: ->
    @submit_button.removeClass('disabled')

  select_content: (e) ->
    $(e.target).select()

  # shoud update duration and time values
  on_slide_change: (e) ->
    # duration is in minutes
    duration = (e.value[1] - e.value[0]) * 60

    # Update duration
    @duration_field.val duration
    # Update times
    @start_field.val @float_to_time(e.value[0])
    @end_field.val @float_to_time(e.value[1])

  # should update time and slider values
  on_duration_change: (e) ->
    duration = $(e.target).val()
    slider = @slider_div.data('slider')

    values = slider.getValue()
    # I have to write it. JS sucks.
    values[1] = values[0] + parseFloat((duration / 60).toFixed(2))

    # Update slider
    slider.setValue(values)
    # Update times
    @start_field.val @float_to_time(values[0])
    @end_field.val @float_to_time(values[1])

  # should update duration and slider
  on_time_change: (e) ->
    value = $(e.target).val()
    if value
      success = false
      if value.match(":")
        success = true

      # Matches 1015
      v = value.match(/([0-9]+)([0-9]{2})/)
      if v and v.length == 3
        v.splice(0,1)
        $(e.target).val(v.join(":"))
        success = true

      # Matches 12
      v = value.match(/^([0-9]{1,2})$/)
      if v and v.length == 2
        v.splice(0,1)
        $(e.target).val(v + ":00")
        success = true

      if success
        start = @time_to_float @start_field.val()
        end   = @time_to_float @end_field.val()
        duration =
        # Update slider
        slider = @slider_div.data('slider')
        slider.setValue([start, end])

        # Update duration
        @duration_field.val (60 * (end - start)).toFixed(0)

      else
        # bad luck
        $(e.target).val("")

  float_to_time: (f) ->
    h = Math.floor f
    m = parseInt((60 * (f - h)).toPrecision(2))
    h.pad(2) + ":" + m.pad(2)

  time_to_float: (ts) ->
    f = parseFloat(ts.split(":").join("."))
    h = Math.floor f
    m = (f - h) / 60 * 100
    h + m

  time_to_hours: (ts) ->
    parseFloat ts.split(":")[0]

  time_to_minutes: (ts) ->
    parseFloat ts.split(":")[1]

  repack_date_time:  ->
    d = @date_field.val().split("-")
    start_time = @start_field.val()

    # start date is a datetime
    new Date(d[2], d[1], d[0], @time_to_hours(start_time), @time_to_minutes(start_time))

class New extends TimesheetController

  events:
    'submit form': 'submit'
    'slide': 'on_slide_change'
    'keyup #task_duration': 'on_duration_change'
    'focus .time': 'select_content'
    'blur .time': 'on_time_change'

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

class Edit extends TimesheetController

  events:
    'submit form': 'submit'
    'task-destroy': 'destroy'
    'slide': 'on_slide_change'
    'keyup #task_duration': 'on_duration_change'
    'focus .time': 'select_content'
    'blur .time': 'on_time_change'
    'click button[name=reset_value]': 'reset_value'

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
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications(@task)

  reset_value: () ->
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
    @task = $(e.target).task()
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

