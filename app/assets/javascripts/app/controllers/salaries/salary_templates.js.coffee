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

SalarySalaryTemplate = App.SalarySalaryTemplate
Language = App.Language

$.fn.salary_template = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  SalarySalaryTemplate.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form' : 'submit'
    'click #salary_template_placeholder_button':   "toggle_placeholders"

  constructor: ->
    super
    get_callback = (data) =>
      @placeholders = data
    $.get(SalarySalaryTemplate.url() + "/placeholders", get_callback, 'json')

  active: ->
    @render()

  render: =>
    if @placeholders
      @salary_template = new SalarySalaryTemplate(placeholders: @placeholders)
      @salary_template.html = @view('salaries/salary_templates/template')(@)
      @html @view('salaries/salary_templates/form')(@)
      Ui.load_ui(@el)
      $(@el).modal('show')

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @salary_template.load(data)
    @save_with_notifications @salary_template, @close

  toggle_placeholders: ->
    $("#salary_template_placeholders_list").toggle('fold')


class Edit extends App.ExtendedController
  events:
    'submit form' : 'submit'
    'click #salary_template_placeholder_button':   "toggle_placeholders"

  active: (params) ->
    @id = params.id if params.id
    @render()

  render: =>
    return unless SalarySalaryTemplate.exists(@id)
    @show()
    @salary_template = SalarySalaryTemplate.find(@id)
    @html @view('salaries/salary_templates/form')(@)
    Ui.load_ui(@el)
    @open()

  submit: (e) =>
    e.preventDefault()
    data = $(e.target).serializeObject()
    @salary_template.load(data)
    @save_with_notifications @salary_template, @close

  toggle_placeholders: ->
    $("#salary_template_placeholders_list").toggle('fold')

class Index extends App.ExtendedController
  events:
    'salary_template-edit':      'edit'
    'salary_template-destroy':   'destroy'
    'click input[type="submit"]': 'new'

  constructor: (params) ->
    super
    SalarySalaryTemplate.bind('refresh', @render)
    Language.bind('refresh', @unlock_new)

  render: =>
    @html @view('salaries/salary_templates/index')(@)
    Ui.load_ui(@el)
    @unlock_new() if @new_unlocked

  new: (e) ->
    @trigger 'new'

  edit: (e) ->
    salary_template = $(e.target).salary_template()
    @trigger 'edit', salary_template.id

  destroy: (e) ->
    salary_template = $(e.target).salary_template()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications salary_template

  unlock_new: (e) =>
    @el.find('input[type="submit"]').button('enable')
    @new_unlocked = true

class App.SalariesTemplates extends Spine.Controller
  className: 'salaries_salary_templates'

  constructor: (params) ->
    super

    @edit_template_window = Ui.stack_window('edit-html-template-window', {width: 1000, position: 'top', remove_on_close: false})
    $(@edit_template_window).modal({title: I18n.t('salaries.salary_template.views.edit_template')})

    @new_template_window = Ui.stack_window('new-html-template-window', {width: 1000, position: 'top', remove_on_close: false})
    $(@new_template_window).modal({title: I18n.t('salaries.salary_template.views.new_template')})

    @index = new Index
    @edit = new Edit({el: @edit_template_window})
    @new = new New({el: @new_template_window})

    @append(@index)

    @index.bind 'edit', (id) => @edit.active(id: id)
    @index.bind 'new', => @new.active()

    @index.bind 'destroyError', (id, errors) =>
      @edit.active id: id
      @edit.render_errors errors

  activate: ->
    super
    Language.fetch()
    SalarySalaryTemplate.fetch()
