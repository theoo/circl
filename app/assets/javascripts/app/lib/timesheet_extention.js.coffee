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

class App.TimesheetExtention extends App.ExtendedController

  constructor: ->
    super

  render: =>
    @task.slider_values = "[" +
      @time_to_float(@task.start_time) + "," +
      @time_to_float(@task.end_time) + "]"

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
    @task_type_description_div = @el.find("#task_type_description")
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

    @update_task_type_description()

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
    # Clear value
    @value_field.val(null)

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

    # Clear value
    @value_field.val(null)

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

        # Clear value
        @value_field.val(null)

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

  update_task_type_description: (e) ->
    id = @task_type_field.val()
    task_type = App.TaskType.find(id)
    @task_type_description_div.html task_type.description