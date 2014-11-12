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

PersonAffairExtra = App.PersonAffairExtra

$.fn.extra = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'currency_changed select.currency_selector': 'on_currency_change'
    'click a[name="reset"]': 'reset'

  constructor: ->
    super
    @setup_vat
      ids_prefix: 'person_affair_extra_'
      bind_events: (App.ApplicationSetting.value('use_vat') == "true")

  active: (params) =>
    if params
      @person_id = params.person_id if params.person_id
      if App.Person.exists(@person_id)
        @person = App.Person.find(@person_id)

      @affair_id = params.affair_id if params.affair_id
      if App.PersonAffair.exists(@affair_id)
        @affair = App.PersonAffair.find(@affair_id)

      @can = params.can if params.can

    @render()

  render: =>
    @show()
    @extra = new PersonAffairExtra(quantity: 1)
    @extra.vat_percentage = @affair.vat_percentage if @affair
    @html @view('people/affairs/extras/form')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairExtra.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @extra.fromForm(e.target), =>
      @render()
      App.PersonAffair.fetch(id: @affair_id)


class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click a[name="cancel"]': 'cancel'
    'click a[name=person-affair-extra-destroy]': 'destroy'
    'currency_changed select.currency_selector': 'on_currency_change'

  constructor: ->
    super
    @ids_prefix = 'person_affair_extra_'
    @setup_vat
      ids_prefix: @ids_prefix
      bind_events: (App.ApplicationSetting.value('use_vat') == "true")

  active: (params) =>
    if params
      @id = params.id if params.id
      @person_id = params.person_id if params.person_id
      if App.Person.exists(@person_id)
        @person = App.Person.find(@person_id)

      @affair_id = params.affair_id if params.affair_id
      if App.PersonAffair.exists(@affair_id)
        @affair = App.PersonAffair.find(@affair_id)

      @can = params.can if params.can
    @render()

  render: =>
    return unless PersonAffairExtra.exists(@id) && @can
    @extra = PersonAffairExtra.find(@id)
    @html @view('people/affairs/extras/form')(@)
    @show()
    if App.ApplicationSetting.value('use_vat') == "true"
      @highlight_vat()

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairExtra.url() == undefined

  submit: (e) ->
    e.preventDefault()
    @save_with_notifications @extra.fromForm(e.target), =>
      @hide()
      App.PersonAffair.fetch(id: @affair_id)

  destroy: (e) ->
    e.preventDefault()
    @confirm I18n.t('common.are_you_sure'), 'warning', =>
      @destroy_with_notifications @extra, =>
        @hide()
        App.PersonAffair.fetch(id: @affair_id)

class Index extends App.ExtendedController
  events:
    'click tr.item':      'edit'
    'datatable_redraw': 'table_redraw'
    'click a[name=affair-extras-csv]': 'csv'
    'click a[name=affair-extras-pdf]': 'pdf'
    'click a[name=affair-extras-odt]': 'odt'
    'click a[name=affair-extras-preview]': 'preview'

  constructor: (params) ->
    super
    PersonAffairExtra.bind('refresh', @render)

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    @html @view('people/affairs/extras/index')(@)

    refresh_index = =>
      PersonAffairExtra.fetch()

    @el.find('table.datatable')
      .rowReordering(
        sURL: PersonAffairExtra.url() + "/change_order"
        sRequestType: "GET"
        iIndexColumn: 0
        fnSuccess: refresh_index)

    if @disabled() then @disable_panel() else @enable_panel()

  disabled: =>
    PersonAffairExtra.url() == undefined

  edit: (e) ->
    @id = $(e.target).extra()
    @activate_in_list e.target
    @trigger 'edit', @id

  table_redraw: =>
    if @id
      target = $(@el).find("tr[data-id=#{@id}]")

    @activate_in_list(target)

  csv: (e) ->
    e.preventDefault()
    window.location = PersonAffairExtra.url() + ".csv"

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_extras_template").val()
    window.location = PersonAffairExtra.url() + ".pdf?template_id=#{@template_id}"

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_extras_template").val()
    window.location = PersonAffairExtra.url() + ".odt?template_id=#{@template_id}"

  preview: (e) ->
    e.preventDefault()
    @template_id = @el.find("#affair_extras_template").val()

    win = $("<div class='modal fade' id='affair-extras-preview' tabindex='-1' role='dialog' />")
    # render partial to modal
    modal = JST["app/views/helpers/modal"]()
    win.append modal
    win.modal(keyboard: true, show: false)

    # Update title
    win.find('h4').text I18n.t('common.preview')

    # Insert iframe to content
    iframe = $("<iframe src='" +
                "#{PersonAffairExtra.url()}.html?template_id=#{@template_id}" +
                "' width='100%' " + "height='" + ($(window).height() - 60) +
                "'></iframe>")
    win.find('.modal-body').html iframe

    # Adapt width to A4
    win.find('.modal-dialog').css(width: 900)

    # Add preview in new tab button
    btn = "<button type='button' name='affair-extras-preview-in-new-tab' class='btn btn-default'>"
    btn += I18n.t('affair.views.actions.preview_in_new_tab')
    btn += "</button>"
    btn = $(btn)
    win.find('.modal-footer').append btn
    btn.on 'click', (e) =>
      e.preventDefault()
      window.open "#{PersonAffairExtra.url()}.html?template_id=#{@template_id}", "affair_extras_preview"

    win.modal('show')

class App.PersonAffairExtras extends Spine.Controller
  className: 'extras'

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

  activate: (params) ->
    super

    if params
      @person_id = params.person_id if params.person_id
      @affair_id = params.affair_id if params.affair_id

    App.Permissions.get { person_id: @person_id, can: { extra: ['create', 'update'] }}, (data) =>
      @new.active { person_id: @person_id, affair_id: @affair_id, can: data }
      @index.active { person_id: @person_id, affair_id: @affair_id, can: data }
      @edit.active { person_id: @person_id, affair_id: @affair_id, can: data }
      @edit.hide()
