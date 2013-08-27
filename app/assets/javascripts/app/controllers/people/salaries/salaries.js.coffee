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

Person = App.Person
Salary = App.Salary

$.fn.salary = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Salary.find(elementID)

class Index extends App.ExtendedController
  events:
    'submit form'    : 'new'
    'salary-edit'    : 'edit'
    'salary-pdf'     : 'pdf'
    'salary-preview' : 'preview'
    'salary-destroy' : 'destroy'

  constructor: (params) ->
    super
    @person_id = params.person_id if params.person_id
    @view_url = params.view_url if params.view_url
    Person.bind('refresh', @render)
    Salary.bind('refresh', @render)

  render: =>
    if Person.all().length == 1
      @person = Person.first()
      @html @view(@view_url)(@)
      Ui.load_ui(@el)

  new: (e) ->
    e.preventDefault()
    salary = new Salary
    salary = salary.fromForm(e.target)
    salary.is_reference = (salary.is_reference == 'true')

    if salary.parent_id
      # copy reference in this new salary
      reference = Salary.find(salary.parent_id)
      salary.salary_template_id = reference.salary_template_id
      salary.activity_rate      = reference.activity_rate
      salary.children_count     = reference.children_count
      salary.married            = reference.married
      salary.title              = reference.title
      salary.brut_account       = reference.brut_account
      salary.net_account        = reference.net_account
      salary.employer_account   = reference.employer_account
      salary.paid               = reference.paid

      salary.from             = '01-01-2013'
      salary.to             = '31-01-2013'
    else
      # defaults
      now = new Date
      year = now.getFullYear()

      salary.paid                = false
      salary.married             = false
      salary.children_count      = 0
      salary.activity_rate       = 80
      salary.yearly_salary_count = 12
      salary.from                = "01-01-" + year
      salary.to                  = "31-12-" + year

    @trigger 'new', salary

  edit: (e) ->
    salary = $(e.target).salary()
    @trigger 'edit', salary

  pdf: (e) ->
    salary = $(e.target).salary()
    window.location = "#{Salary.url()}/#{salary.id}.pdf"

  preview: (e) ->
    salary = $(e.target).salary()
    win = Ui.stack_window('preview-salary', {width: 900, height: $(window).height(), remove_on_close: true})
    $(win).modal({title: I18n.t('salaries.views.contextmenu.preview_pdf')})
    iframe = $("<iframe src='" +
                "#{Salary.url()}/#{salary.id}.html" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    $(win).html iframe
    $(win).modal('show')

  destroy: (e) ->
    salary = $(e.target).salary()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications(salary)

class App.PersonSalaries extends Spine.Controller
  className: 'people_salaries_salaries'

  constructor: (params) ->
    super

    @person_id = params.person_id

    Salary.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/salaries"

    @salary_index = new Index(person_id: @person_id, view_url: 'people/salaries/salaries/index')
    @salary_index.bind('new', @new)
    @salary_index.bind('edit', @edit)

    @reference_index = new Index(person_id: @person_id, view_url: 'people/salaries/references/index')
    @reference_index.bind('new', @new)
    @reference_index.bind('edit', @edit)

    # Render errors on index
    @salary_index.bind 'destroyError', (id, errors) =>
      @salary_index.renderErrors errors

    @reference_index.bind 'destroyError', (id, errors) =>
      @reference_index.renderErrors errors

    @append(@salary_index, @reference_index)

  new: (salary) ->
    window = Ui.stack_window('edit-salary-window', {fullscreen: true, people_salaries_salariestion: 'top', remove_on_close: true})
    controller = new App.SalaryEditor({el: window, salary: salary})
    $(window).modal({title: I18n.t('salaries.salary.views.new_salary')})
    $(window).modal('show')
    controller.activate()

  edit: (salary) ->
    window = Ui.stack_window('edit-salary-window', {fullscreen: true, position: 'top', remove_on_close: true})
    controller = new App.SalaryEditor({el: window, salary: salary})
    $(window).modal({title: I18n.t('salaries.salary.views.edit_salary')})
    $(window).modal('show')
    controller.activate()

  activate: ->
    super
    Salary.fetch()
    # Require personnal information to render salaries
    if App.Person.all().length == 0
      App.Person.fetch {id: @person_id}

    # @salary_index.render()
    # @reference_index.render()
