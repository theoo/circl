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
Permissions = App.Permissions

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
    'click a[name="reset"]': 'reset'

  constructor: (params) ->
    super
    PersonTask.bind('refresh', @render)

  active: (params) =>
    if params
      @person_id = params.person_id if params.person_id
      @person = App.Person.find(@person_id)
      @affair_id = params.affair_id if params.affair_id
      @can = params.can if params.can
    @render()

  render: =>
    if @person.task_rate_id > 0 and App.TaskType.count() > 0 and App.TaskRate.count() > 0
      @task = new PersonTask

      @task.owner_name = @person.name
      @task.owner_id = @person.id

      if @affair_id and App.PersonAffair.exists(@affair_id)
        @affair = App.PersonAffair.find @affair_id
        @task.affair_title = @affair.title
        @task.affair_id = @affair.id

      @task.start_date = (new Date).to_view()
      @task.start_time = '09:00'
      @task.end_time = '18:00'
      @task.duration = 9 * 60

      super

      if @disabled() then @disable_panel() else @enable_panel()

      # Disable owner and affair selection which makes sens only
      # on dashboard page
      @el.find("#task_owner_affair input").each (i,e) =>
        $(e).prop('disabled', true)

    else
      if App.TaskType.count() == 0
        @html @view('people/affairs/tasks/no_task_type')(@)

      if App.TaskRate.count() == 0
        @html @view('people/affairs/tasks/no_task_rate')(@)
      else
        unless @person.task_rate_id
          @html @view('people/affairs/tasks/no_rate_selected')(@)

      if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonTask.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @task.fromForm(e.target)
    @task.start_date = @repack_date_time(@task.start_date)
    @save_with_notifications @task, =>
      @render()
      App.PersonAffair.fetch(id: @affair_id)

class Edit extends App.TimesheetExtention

  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click button[name=task-destroy]': 'destroy'
    'slide': 'on_slide_change'
    'keyup #task_duration': 'on_duration_change'
    'focus .time': 'select_content'
    'blur .time': 'on_time_change'
    'click button[name=reset_value]': 'reset_value'
    'change select[name=task_type_id]': 'update_task_type_description'
    'click a[name="affair-task-preview-pdf"]': 'preview'
    'click a[name="affair-task-download-pdf"]': 'pdf'
    'click a[name="affair-task-download-odt"]': 'odt'

  constructor: ->
    super

  active: (params) ->
    if params
      @id = params.id if params.id
      @can = params.can if params.can
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id
      @can = params.can if params.can
    if @id and PersonTask.exists(@id)
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
    @save_with_notifications @task, =>
      @hide()
      App.PersonAffair.fetch(id: @affair_id)

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications @task, =>
        @hide()
        App.PersonAffair.fetch(id: @affair_id)

  reset_value: (e) ->
    e.preventDefault()
    @value_field.val @task.computed_value


class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=affair-tasks-csv]': 'csv'
    'click a[name=affair-tasks-pdf]': 'pdf'
    'click a[name=affair-tasks-odt]': 'odt'
    'click a[name=affair-tasks-preview]': 'preview'

  constructor: (params) ->
    super
    PersonTask.bind('refresh', @render)

  active: (params) ->
    if params and params.task_id
      @task = PersonTask.find(params.task_id)
    @render()

  render: =>
    @html @view('people/affairs/tasks/index')(@)

  edit: (e) ->
    e.preventDefault()
    @task = $(e.target).task()
    @activate_in_list(e.target)
    @trigger 'edit', @task.id

  table_redraw: =>
    if @task
      target = $(@el).find("tr[data-id=#{@task.id}]")
    @activate_in_list(target)

  csv: (e) ->
    e.preventDefault()
    window.location = PersonTask.url() + ".csv"

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_tasks_template").val()
    window.location = PersonTask.url() + ".pdf?template_id=#{@template_id}"

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_tasks_template").val()
    window.location = PersonTask.url() + ".odt?template_id=#{@template_id}"

  preview: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_tasks_template").val()

    win = $("<div class='modal fade' id='affair-tasks-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.preview')

    # Insert iframe to content
    iframe = $("<iframe src='" +
                "#{PersonTask.url()}.html?template_id=#{@template_id}" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    win.find('.modal-body').html iframe

    # Adapt width to A4
    win.find('.modal-dialog').css(width: 900)

    # Add preview in new tab button
    btn = "<button type='button' name='affair-tasks-preview-in-new-tab' class='btn btn-default'>"
    btn += I18n.t('affair.views.actions.preview_in_new_tab')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonTask.url()}.html?template_id=#{@template_id}", "affair_tasks_preview"

    win.modal('show')

class App.PersonAffairTasks extends Spine.Controller
  className: 'tasks'

  constructor: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

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

  activate: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    TaskType.one 'refresh', =>
      Permissions.get { person_id: @person_id, can: { task: ['create', 'update'] }}, (data) =>
        @edit.hide()
        @edit.active {can: data}
        @new.active { person_id: @person_id, affair_id: @affair_id, can: data }
        @index.active {can: data}

    # FIXME TaskType will be reloaded on each affair change
    TaskType.fetch
      data:
        actives: true
      processData: true


