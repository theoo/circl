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

$ = jQuery.sub()
PersonTask = App.PersonTask

$.fn.task = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonTask.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  render: =>
    @task = new PersonTask
    @html @view('people/tasks/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @task.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless PersonTask.exists(@id)
    @show()
    @task = PersonTask.find(@id)
    @html @view('people/tasks/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @task.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'task-edit':    'edit'
    'task-destroy': 'destroy'

  constructor: (params) ->
    super
    PersonTask.bind('refresh', @render)

  render: =>
    @html @view('people/tasks/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    task = $(e.target).task()
    @trigger 'edit', task.id

  destroy: (e) ->
    task = $(e.target).task()
    if confirm(I18n.t("common.are_you_sure"))
      @destroy_with_notifications(task)

class App.PersonTasks extends Spine.Controller
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

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.renderErrors errors

  activate: ->
    super
    PersonTask.fetch()
    @new.render()
