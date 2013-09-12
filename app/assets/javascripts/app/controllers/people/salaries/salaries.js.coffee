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
SalaryTemplate = App.SalaryTemplate

$.fn.salary = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  Salary.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'change #person_salary_parent_id': 'reference_selected'

  constructor: (params) ->
    super
    @person = Person.find(@person_id)
    Salary.bind('refresh', @active)
    SalaryTemplate.bind('refresh', @active)

  get_reference_id:  =>
    id = $("#person_salary_parent_id").find("option:selected").val()
    id ||= Salary.findAllByAttribute("is_reference", true)[0].id
    id

  is_new_reference:  =>
    @get_reference_id() == 'new'

  reference_selected: (e) =>
    @new_reference_selected = @is_new_reference()
    @render()

  active: =>
    super
    if Salary.all().length > 0 and SalaryTemplate.all().length > 0
      @new_reference_selected = SalaryTemplate.all().length == 0
      @render()

  render: =>
    @salary = new Salary

    if @is_new_reference() or @new_reference_selected
      @salary.is_reference        = true
      @salary.paid                = false
      @salary.married             = false
      @salary.children_count      = 0
      @salary.yearly_salary_count = 12
    else
      # copy reference in this new salary
      reference = Salary.find(@get_reference_id())
      @salary.salary_template_id = reference.salary_template_id
      @salary.activity_rate      = reference.activity_rate
      @salary.children_count     = reference.children_count
      @salary.married            = reference.married
      @salary.title              = reference.title
      @salary.brut_account       = reference.brut_account
      @salary.net_account        = reference.net_account
      @salary.employer_account   = reference.employer_account
      @salary.paid               = reference.paid
      @salary.parent_id          = reference.id

    # defaults
    now = new Date
    year = now.getFullYear()
    @salary.from                = "01-01-" + year
    @salary.to                  = "31-12-" + year
    @html @view('people/salaries/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()

    data = $(e.target).serializeObject()
    @salary.load(data)

    @salary.married = data.married?
    @salary.paid = data.paid?

    @save_with_notifications @salary, (id) =>
      @render()

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'change #person_salary_parent_id': 'reference_selected'

  constructor: (params) ->
    super
    @person = Person.find(@person_id)
    # Salary.bind('refresh', @active)
    # SalaryTemplate.bind('refresh', @active)

  get_reference_id:  =>
    id = $("#person_salary_parent_id").find("option:selected").val()
    id ||= Salary.findAllByAttribute("is_reference", true)[0].id
    id

  is_new_reference:  =>
    @get_reference_id() == 'new'

  reference_selected: (e) =>
    @new_reference_selected = @is_new_reference()
    @render()

  active: (params) =>
    super
    @id = params.id if params.id
    @render()

  render: =>
    @salary = Salary.find(@id)
    @html @view('people/salaries/form')(@)
    Ui.load_ui(@el)

  submit: (e) ->
    e.preventDefault()

    data = $(e.target).serializeObject()
    @salary.load(data)

    @salary.married = data.married?
    @salary.paid = data.paid?

    @save_with_notifications @salary, (id) =>
      @render()

class Index extends App.ExtendedController
  events:
    'click tr.item'    : 'edit'
    #'salary-pdf'     : 'pdf'
    #'salary-preview' : 'preview'
    #'salary-destroy' : 'destroy'

  constructor: (params) ->
    super
    @person_id = params.person_id if params.person_id
    @reference = params.reference if params.reference
    Person.bind('refresh', @render)
    Salary.bind('refresh', @render)

  render: =>
    if Person.all().length == 1
      @person = Person.first()

      if @reference
        @html @view('people/salaries/references_index')(@)
      else
        @html @view('people/salaries/index')(@)

      Ui.load_ui(@el)

  edit: (e) ->
    salary = $(e.target).salary()
    @trigger 'edit', salary.id

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

    @new = new New(person_id: @person_id)
    @edit = new Edit(person_id: @person_id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @salary_index = new Index(person_id: @person_id, reference: false )
    @salary_index.bind 'edit', (id) =>
      @edit.active(id: id)

    @reference_index = new Index(person_id: @person_id, reference: true )
    @reference_index.bind 'edit', (id) =>
      @edit.active(id: id)

    # Render errors on index
    @salary_index.bind 'destroyError', (id, errors) =>
      @salary_index.render_errors errors

    @reference_index.bind 'destroyError', (id, errors) =>
      @reference_index.render_errors errors

    @append(@new, @salary_index, @reference_index)

  activate: ->
    super
    Salary.fetch()
    SalaryTemplate.fetch()
