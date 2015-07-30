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
Permissions = App.Permissions
Language = App.Language
PersonCommentSummary = App.PersonCommentSummary

$.fn.item = ->
  elementID   = $(@).data('id')
  elementID or= $(@).parents('[data-id]').data('id')
  Person.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click #person_map': 'open_map'
    'click a[name="reset"]': 'reset'

  open_map: (e) ->
    e.preventDefault()

  constructor: (params) ->
    super

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    return unless @can
    @show()
    @person = new Person()
    @html @view('people/form')(@)

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @person.load(data)
    @person.is_an_organization = data.is_an_organization?
    @person.hidden = data.hidden?

    # Custom @save_with_notifications @person
    @person.bind 'ajaxSuccess', (newrecord, data, statusText, xhr) =>
      window.location = [Person.url(), data.id].join("/")

    @person.bind 'ajaxError', (unused, xhr, statusText, error) =>
      # On error, destroy the record that was inserted by Spine
      @person.unbind(@)
      @person.destroy ajax: false
      @render_errors $.parseJSON(xhr.responseText)

    @person.save()

class Edit extends App.ExtendedController
  events:
    'submit form': 'submit'
    'click #person_map': 'open_map'
    'click a[name=person_email_button]': 'mail_to'
    'click a[name=person_second_email_button]': 'mail_to'
    'click a[name=person_phone_button]': 'call_to'
    'click a[name=person_second_phone_button]': 'call_to'
    'click a[name=person_mobile_button]': 'call_to'
    'click a[name=person_website_button]': 'link_to'
    'click a[name="person_preview"]': 'pdf'
    'click a[name="person_pdf"]': 'pdf'
    'click a[name="person_odt"]': 'odt'
    'focusin input[name=website]': 'append_http'
    'focusout input[name=website]': 'remove_http'
    'click #person_comments_summary tr.item': 'switch_to_comments'

  constructor: (params) ->
    super
    @id = params.id
    Language.bind 'refresh', @render
    PersonCommentSummary.bind 'refresh', @render

  active: (params) ->
    @can = params.can if params.can
    @render()

  render: =>
    return unless @can && Person.exists(@id)
    @show()
    @person = Person.find(@id)
    @html @view('people/form')(@)
    $("a[name=person_email_button]").attr(disabled: true)         unless @person.email
    $("a[name=person_second_email_button]").attr(disabled: true)  unless @person.second_email
    $("a[name=person_phone_button]").attr(disabled: true)         unless @person.phone
    $("a[name=person_second_phone_button]").attr(disabled: true)  unless @person.second_phone
    $("a[name=person_mobile_button]").attr(disabled: true)        unless @person.mobile
    $("a[name=person_website_button]").attr(disabled: true)       unless @person.website

  submit: (e) ->
    e.preventDefault()
    data = $(e.target).serializeObject()
    @person.load(data)
    @person.is_an_organization = data.is_an_organization?
    @person.hidden = data.hidden?
    @save_with_notifications @person, =>
      @render()
      @update_name_titles()

  update_name_titles: =>
    title = $("#pagination_title")
    if title.length > 0
      title.html @person.name

    title = $("a[href=#info_tab]")
    if title.length > 0
      title.html @person.name

  open_map: (e) ->
    e.preventDefault()
    window.open "#{Person.url()}/#{@person.id}/map.html", "person_map"

  mail_to: (e) ->
    e.preventDefault()
    email = $(e.target).closest(".input-group").find("input").val()
    window.location = "mailto:#{email}"

  call_to: (e) ->
    e.preventDefault()
    phone = $(e.target).closest(".input-group").find("input").val().split(" ").join("")
    window.location = "callto:#{phone}"

  link_to: (e) ->
    e.preventDefault()
    url = $(e.target).closest(".input-group").find("input").val()
    window.open(url, 'person_website')

  append_http: (e) ->
    e.preventDefault()
    input = $(e.target)
    if input.val() == ""
      input.val("http://www.")

  remove_http: (e) ->
    e.preventDefault()
    input = $(e.target)
    if input.val() == "http://www."
      input.val("")

  switch_to_comments: (e) ->
    e.preventDefault()
    $("a[href='#activities_tab']").click()

  pdf: (e) ->
    e.preventDefault()
    @template_id = @el.find("#person_template").val()
    window.location = "#{Person.url()}/#{@person.id}.pdf?template_id=#{@template_id}"

  odt: (e) ->
    e.preventDefault()
    @template_id = @el.find("#person_template").val()
    window.location = "#{Person.url()}/#{@person.id}.odt?template_id=#{@template_id}"

class App.People extends Spine.Controller
  className: 'person'

  constructor: (params) ->
    super

    @person_id = params.person_id if params

    PersonCommentSummary.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/comments?summary=true"

    @edit = new Edit(id: @person_id)
    @new = new New()
    @append(@new, @edit)

    @edit.bind 'show', => @new.hide()
    @edit.bind 'hide', => @new.show()

  activate: ->
    super
    # TODO refactor permissions with spine and ensure it's loaded before any other actions
    permissions_hash =
      person: [ 'destroy',
        'restricted_attributes',
        'authenticate_using_token',
        'creditor_information',
        'view_comments_on_profile_page']
      comment: [ 'read' ]

    on_permissions_refresh = (data) =>
      Language.one 'refresh', =>
        load_person = =>
          if @person_id
            @edit.active { can: data }
          else
            @new.active { can: data }

        if @person_id
          PersonCommentSummary.one 'refresh', => load_person()
          PersonCommentSummary.fetch()
        else
          load_person()

      Language.fetch()

    Permissions.get(
      person_id: @person_id
      can: permissions_hash
      , on_permissions_refresh)



