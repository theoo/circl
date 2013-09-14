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
    'change #person_salary_parent_id': 'render'

  constructor: (params) ->
    super
    Person.bind 'refresh', @active
    Salary.bind 'refresh', @active
    # FIXME Ref selection doesn't work if this callback is set (?)
    # SalaryTemplate.bind 'refresh', @active

  get_reference_id:  =>
    # (Try to) fetch reference_id from DOM
    id = $("#person_salary_parent_id").find("option:selected").val()
    unless id
      # If not found but a salary exists
      console.log Salary.all()
      if Salary.all().length >  0
        # Select its first reference (it may not be possible to have a salary without reference)
        console.log Salary.findAllByAttribute("is_reference", true)
        id = Salary.findAllByAttribute("is_reference", true)[0].id
      else
        # Absolutely no salary exists, force to create a reference first.
        id = 'new'
    console.log id
    id

  is_new_reference:  =>
    @get_reference_id() == 'new'

  active: =>
    super
    @person = Person.find(@person_id)
    @render()

  render: =>
    @salary = new Salary

    @new_reference_selected = @is_new_reference()

    if @new_reference_selected
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
    'click a[name="salary-download-pdf"]': 'pdf'
    'click a[name="salary-preview-pdf"]': 'preview'
    'click button[name="salary-destroy"]': 'destroy'

  constructor: (params) ->
    super

  get_reference_id:  =>
    # (Try to) fetch reference_id from DOM
    id = $("#person_salary_parent_id").find("option:selected").val()
    unless id
      # If not found but a salary exists
      if Salary.all().length >  0
        # Select its first reference (it may not be possible to have a salary without reference)
        id ||= Salary.findAllByAttribute("is_reference", true)[0].id
      else
        # Absolutely no salary exists, force to create a reference first.
        id = 'new'
    id

  is_new_reference:  =>
    @get_reference_id() == 'new'

  reference_selected: (e) =>
    @new_reference_selected = @is_new_reference()
    @render()

  active: (params) =>
    super
    @person = Person.find(@person_id)
    @id = params.id if params.id
    @render()
    @show()

  render: =>
    @salary = Salary.find(@id)
    @html @view('people/salaries/form')(@)
    Ui.load_ui(@el)
    select = $(@el).find("#person_salary_parent_id")
    select.prop('disabled', true)
    if @salary.is_reference
      select.find('option').filter(-> $(@).val() == 'new').prop('selected', true)

  pdf: (e) ->
    e.preventDefault()
    window.location = "#{Salary.url()}/#{@salary.id}.pdf"

  preview: (e) ->
    e.preventDefault()

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @destroy_with_notifications(@salary)

  submit: (e) ->
    e.preventDefault()

    data = $(e.target).serializeObject()
    @salary.load(data)

    @salary.married = data.married?
    @salary.paid = data.paid?

    @save_with_notifications @salary, (id) =>
      @hide()

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'

  constructor: (params) ->
    super
    @person_id = params.person_id if params.person_id
    Person.bind('refresh', @render)
    Salary.bind('refresh', @render)

  render: =>
    @person = Person.first()
    @html @view('people/salaries/index')(@)
    Ui.load_ui(@el)
    $("#person_salaries_nav a:first").tab('show')

  edit: (e) ->
    e.preventDefault()
    salary = $(e.target).salary()
    @trigger 'edit', salary.id

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

    # index
    @index = new Index(person_id: @person_id)
    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @index.bind 'edit', (id) =>
      @edit.active(id: id)
    @index.bind 'destroyError', (id, errors) =>
      @salary_index.render_errors errors

    @append(@new, @edit, @index)

  activate: ->
    super
    Salary.fetch()
    SalaryTemplate.fetch()
