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
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @job.fromForm(e.target), @render

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: ->
    super

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless Job.exists(@id)
    @show()
    @job = Job.find(@id)
    @html @view('settings/jobs/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @job.fromForm(e.target), @hide

class Index extends App.ExtendedController
  events:
    'job-edit':      'edit'
    'job-destroy':   'destroy'
    'job-members':   'view_members'

  constructor: (params) ->
    super
    Job.bind('refresh', @render)

  render: =>
    @html @view('settings/jobs/index')(@)
    Ui.load_ui(@el)

  edit: (e) ->
    job = $(e.target).job()
    @trigger 'edit', job.id

  view_members: (e) ->
    job = $(e.target).job()
    App.search_query(search_string: "job.id:#{job.id}")

  destroy: (e) ->
    job = $(e.target).job()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications job

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

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    Job.fetch()
    @new.render()
