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

Job = App.Job

$.fn.job = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Job.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  render: =>
    @job = new Job()
    @html @view('settings/jobs/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @job.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click button[name=settings-job-destroy]': 'destroy'
    'click button[name=settings-job-view-members]': 'view_members'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @job = Job.find(@id)
    @render()

  render: =>
    @show()
    @html @view('settings/jobs/form')(@)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @job.fromForm(e.target), @hide

  view_members: (e) ->
    Directory.search(search_string: "job.id:#{@job.id}")

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @job, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    Job.bind('refresh', @render)

  render: =>
    @html @view('settings/jobs/index')(@)

  edit: (e) ->
    @job = $(e.target).job()
    @activate_in_list e.target
    @trigger 'edit', @job.id

  table_redraw: =>
    if @job
      target = $(@el).find("tr[data-id=#{@job.id}]")

    @activate_in_list(target)

class App.SettingsJobs extends Spine.Controller
  className: 'jobs'

  constructor: (params) ->
    super

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
    Job.fetch()
    @new.render()
