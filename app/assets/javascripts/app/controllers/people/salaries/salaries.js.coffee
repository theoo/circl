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

# NOTE about triggers
# I choose to refresh dependencies with fetch() instead of binding 'refresh'
# trigger for some reasons. Refreshing the view may require to re-fetch
# data which is more complicated if each controller handle every possible
# events instead of telling one controller to refresh its dependencies.

Person = App.Person
PersonSalary = App.PersonSalary
PersonSalaryItem = App.PersonSalaryItem
PersonSalaryTaxData = App.PersonSalaryTaxData
Template = App.GenericTemplate

$.fn.person_salary = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonSalary.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'change #person_salary_parent_id': 'render'

  constructor: (params) ->
    super
    Person.bind 'refresh', @active
    PersonSalary.bind 'refresh', @active

  get_reference_id:  =>
    # (Try to) fetch reference_id from DOM
    id = $("#person_salary_parent_id").find("option:selected").val()
    unless id
      # If not found but a salary exists
      if PersonSalary.all().length >  0
        # Select its first reference (it may not be possible to have a salary without reference)
        id = PersonSalary.findAllByAttribute("is_reference", true)[0].id
      else
        # Absolutely no salary exists, force to create a reference first.
        id = 'new'
    id

  is_new_reference:  =>
    @get_reference_id() == 'new'

  active: =>
    super
    @person = Person.find(@person_id)
    @render()

  render: =>
    @salary = new PersonSalary

    @new_reference_selected = @is_new_reference()

    if @new_reference_selected or PersonSalary.all().length == 0
      @salary.is_reference        = true
      @salary.paid                = false
      @salary.married             = false
      @salary.children_count      = 0
      @salary.yearly_salary_count = 12

      now = new Date
      year = now.getFullYear()
      @salary.from                = "01-01-" + year
      @salary.to                  = "31-12-" + year

    else
      # copy reference in this new salary
      reference = PersonSalary.find(@get_reference_id())
      @salary.generic_template_id = reference.generic_template_id
      @salary.activity_rate       = reference.activity_rate
      @salary.children_count      = reference.children_count
      @salary.married             = reference.married
      @salary.title               = reference.title
      @salary.brut_account        = reference.brut_account
      @salary.net_account         = reference.net_account
      @salary.employer_account    = reference.employer_account
      @salary.paid                = reference.paid
      @salary.parent_id           = reference.id
      @salary.from                = reference.from
      @salary.to                  = reference.to

    # defaults
    @html @view('people/salaries/form')(@)

  submit: (e) ->
    e.preventDefault()

    data = $(e.target).serializeObject()
    @salary.load(data)

    @salary.married = data.married?
    @salary.paid = data.paid?

    @save_with_notifications @salary.fromForm(e.target), (id) =>
      @trigger('edit', id)
      # Update badge
      $('a[href=#salaries_tab] .badge').html PersonSalary.count()


class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'change #person_salary_parent_id':     'reference_selected'
    'click a[name="salary-download-pdf"]': 'pdf'
    'click a[name="salary-download-odt"]': 'odt'
    'click a[name="salary-preview-pdf"]':  'preview'
    'click button[name="salary-destroy"]': 'destroy'

  constructor: (params) ->
    super

  get_reference_id:  =>
    # (Try to) fetch reference_id from DOM
    id = $("#person_salary_parent_id").find("option:selected").val()
    unless id
      # If not found but a salary exists
      if PersonSalary.all().length >  0
        # Select its first reference (it may not be possible to have a salary without reference)
        id ||= PersonSalary.findAllByAttribute("is_reference", true)[0].id
      else
        # Absolutely no salary exists, force to create a reference first.
        id = 'new'
    id

  is_new_reference:  =>
    @get_reference_id() == 'new'

  reference_selected: (e) =>
    e.preventDefault()
    @new_reference_selected = @is_new_reference()
    @render()

  active: (params) =>
    super
    @person = Person.find(@person_id)
    @id = params.id if params.id
    @load_dependencies()
    @render()
    @show()

  load_dependencies: =>
    if @id
      # Required by items and tax_data
      App.SalaryTax.fetch()

      App.SalaryTax.one 'refresh', =>
        # Items
        PersonSalaryItem.url = =>
          "#{Spine.Model.host}/people/#{@person_id}/salaries/#{@id}/items"
        PersonSalaryItem.refresh([], clear: true)
        PersonSalaryItem.fetch()
        person_salary_items_ctrl = $("#person_salary_items").data('controller')
        person_salary_items_ctrl.activate(salary_id: @id)

        # TaxData
        PersonSalaryTaxData.url = =>
          "#{Spine.Model.host}/people/#{@person_id}/salaries/#{@id}/tax_data"
        PersonSalaryTaxData.refresh([], clear: true)
        PersonSalaryTaxData.fetch()
        person_salary_tax_data_ctrl = $("#person_salary_tax_datas").data('controller')
        person_salary_tax_data_ctrl.activate(salary_id: @id)

  unload_dependencies: =>
    # Items
    PersonSalaryItem.url = => undefined
    PersonSalaryItem.refresh([], clear: true)

    # TaxData
    PersonSalaryTaxData.url = => undefined
    PersonSalaryTaxData.refresh([], clear: true)

  render: =>
    @salary = PersonSalary.find(@id)
    @html @view('people/salaries/form')(@)
    select = $(@el).find("#person_salary_parent_id")
    select.prop('disabled', true)
    if @salary.is_reference
      select.find('option').filter(-> $(@).val() == 'new').prop('selected', true)

  pdf: (e) ->
    e.preventDefault()
    window.location = "#{PersonSalary.url()}/#{@salary.id}.pdf"

  odt: (e) ->
    e.preventDefault()
    window.location = "#{PersonSalary.url()}/#{@salary.id}.odt"

  preview: (e) ->
    e.preventDefault()

    win = $("<div class='modal fade' id='salary-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.preview') + ": " + @salary.title

    # Insert iframe to content
    iframe = $("<iframe src='" +
                "#{PersonSalary.url()}/#{@salary.id}.html" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    win.find('.modal-body').html iframe

    # Adapt width to A4
    win.find('.modal-dialog').css(width: 900)

    # Add preview in new tab button
    btn = "<button type='button' name='salary-preview-in-new-tab' class='btn btn-default'>"
    btn += I18n.t('salary.views.actions.preview_in_new_tab')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonSalary.url()}/#{@salary.id}.html", "salary_preview"

    win.modal('show')

  destroy: (e) ->
    e.preventDefault()
    if confirm(I18n.t('common.are_you_sure'))
      @unload_dependencies()
      @destroy_with_notifications @salary, (id) =>
        @hide()
        # Update badge
        $('a[href=#salaries_tab] .badge').html PersonSalary.count()

  submit: (e) ->
    e.preventDefault()

    data = $(e.target).serializeObject()
    @salary.load(data)

    @salary.married = data.married?
    @salary.paid = data.paid?

    @save_with_notifications @salary, (id) =>
      @hide()
      @unload_dependencies()

class Index extends App.ExtendedController
  events:
    'click tr.item': 'edit'
    'datatable_redraw': 'table_redraw'

  constructor: (params) ->
    super
    @person_id = params.person_id if params.person_id
    Person.bind 'refresh', @render
    PersonSalary.bind 'refresh', @render

  active: (params) ->
    if params
      @salary = PersonSalary.find(params.salary_id)

    @render()

  render: =>
    @person = Person.find(@person_id)
    @html @view('people/salaries/index')(@)
    $("#person_salaries_nav a:first").tab('show')

  edit: (e) ->
    e.preventDefault()
    salary = $(e.target).person_salary()
    @activate_in_list(e.target)
    @trigger 'edit', salary.id

  table_redraw: =>
    if @salary
      target = $(@el).find("tr[data-id=#{@salary.id}]")

    @activate_in_list(target)

class App.PersonSalaries extends Spine.Controller
  className: 'people_salaries_salaries'

  constructor: (params) ->
    super

    @person_id = params.person_id

    PersonSalary.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/salaries"

    @new = new New(person_id: @person_id)
    @edit = new Edit(person_id: @person_id)
    @index = new Index(person_id: @person_id)

    @new.bind 'edit', (id) =>
      @edit.active(id: id)
      @index.active(salary_id: id)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

    @index.bind 'edit', (id) =>
      @edit.active(id: id)

    @edit.bind 'destroyError', (id, errors) =>
      @edit.active(id: id)
      @edit.render_errors errors

    @append(@new, @edit, @index)

  activate: ->
    super

    Template.one 'count_fetched', =>
      App.SalaryTax.one 'count_fetched', =>
        PersonSalary.fetch()

      App.SalaryTax.fetch_count()

    Template.fetch_count()
