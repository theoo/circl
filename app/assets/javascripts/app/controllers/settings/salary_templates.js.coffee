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

SalaryTemplate = App.SalaryTemplate
Language = App.Language

$.fn.salary_template = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  SalaryTemplate.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form' : 'submit'

  constructor: ->
    super

  active: ->
    @render()

  render: ->
    @salary_template = new SalaryTemplate
    @salary_template.html = @view('salaries/salary_templates/template')
    @html @view('salaries/salary_templates/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @salary_template.load(data)
    @save_with_notifications @salary_template, (id) =>
      @trigger 'edit', id

class Edit extends App.ExtendedController
  events:
    'submit form' : 'submit'
    'click button[name=salaries-salary-template-destroy]': 'destroy'
    'click button[name=salaries-salary-template-edit]': 'edit_template'

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless SalaryTemplate.exists(@id)
    @show()
    @salary_template = SalaryTemplate.find(@id)
    @html @view('salaries/salary_templates/form')(@)
    Ui.load_ui(@el)

  submit: (e) =>
    e.preventDefault()
    data = $(e.target).serializeObject()
    @salary_template.load(data)
    @save_with_notifications @salary_template, @hide

  edit_template: (e) ->
    e.preventDefault()
    window.open "#{SalaryTemplate.url()}/#{@salary_template.id}/edit.html", "salary_template"

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications @salary_template, @hide

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'

  constructor: (params) ->
    super
    SalaryTemplate.bind('refresh', @render)

  render: =>
    @html @view('salaries/salary_templates/index')(@)
    Ui.load_ui(@el)
    @unlock_new() if @new_unlocked

  new: (e) ->
    @trigger 'new'

  edit: (e) ->
    salary_template = $(e.target).salary_template()
    @trigger 'edit', salary_template.id

class App.SalariesTemplates extends Spine.Controller
  className: 'settings_salary_templates'

  constructor: (params) ->
    super

    @new = new New
    @edit = new Edit
    @index = new Index

    @append(@new, @edit, @index)

    @new.bind 'edit', (id) =>
      @edit.active(id: id)
    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    Language.one "refresh", =>
      SalaryTemplate.fetch()
      @new.render()
    Language.fetch()
