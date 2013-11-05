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

PersonAffairSubscription = App.PersonAffairSubscription

$.fn.person_affair_subscription = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonAffairSubscription.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super
    PersonAffairSubscription.bind('refresh', @render)

  active: (params) =>
    @render()

  disabled: =>
    PersonAffairSubscription.url() == undefined

  render: =>
    @show()
    @html @view('people/affairs/subscriptions/form')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  submit: (e) ->
    e.preventDefault()
    subscription = new PersonAffairSubscription()
    subscription.fromForm(e.target)
    @save_with_notifications subscription, @on_successfull_submit

  on_successfull_submit: ->
    # Refresh affairs
    App.PersonAffair.fetch()
    @render

class Index extends App.ExtendedController
  events:
    'click button[name=subscription-destroy]': 'destroy'

  constructor: (params) ->
    super
    PersonAffairSubscription.refresh([], clear: true)
    PersonAffairSubscription.bind('refresh', @active)

  active: (params) =>
    @render()

  disabled: =>
    PersonAffairSubscription.url() == undefined

  render: =>
    @html @view('people/affairs/subscriptions/index')(@)
    if @disabled() then @disable_panel() else @enable_panel()

  destroy: (e) ->
    e.preventDefault()
    subscription = $(e.target).person_affair_subscription()

    if confirm(I18n.t('common.are_you_sure'))

      ajax_error = (xhr, statusText, error) =>
        @render_errors $.parseJSON(xhr.responseText)

      ajax_success = (data, textStatus, jqXHR) =>
        # Force complete reload
        PersonAffairSubscription.refresh([], clear: true)
        PersonAffairSubscription.fetch()
        # Refresh affairs
        App.PersonAffair.fetch()
        @render_success()

      settings =
        url: PersonAffairSubscription.url(),
        type: 'DELETE',
        data: JSON.stringify(subscription_id: subscription.id)

      PersonAffairSubscription.ajax().ajax(settings).error(ajax_error).success(ajax_success)

# PersonAffairSubscriptions
class App.PersonAffairSubscriptions extends Spine.Controller
  className: 'subscriptions'

  constructor: (params) ->
    super

    @person_id = params.person_id

    @index = new Index
    @new = new New
    @append(@new, @index)

  activate: (params) ->
    super
    # Render empty values (placeholders)
    PersonAffairSubscription.refresh([], clear: true)
    @index.active()
    @new.active()
