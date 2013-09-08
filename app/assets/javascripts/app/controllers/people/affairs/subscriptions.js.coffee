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

# TODO move this into PersonAffairSubscription

PersonAffairSubscription = App.PersonAffairSubscription

$.fn.subscription = ->
  elementID   = $(@).data('id')
  elementID ||= $(@).parents('[data-id]').data('id')
  PersonAffairSubscription.find(elementID)

class New extends App.ExtendedController
  events:
    'submit form': 'submit'

  constructor: (params) ->
    super

  active: (params) ->
    @render()

  render: =>
    @show()
    @html @view('people/affairs/subscriptions/form')(@)
    Ui.load_ui(@el)

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
    'subscription-destroy': 'destroy'

  constructor: (params) ->
    super
    PersonAffairSubscription.refresh([], clear: true)
    PersonAffairSubscription.bind('refresh', @render)

  active: (params) ->
    @render()

  render: =>
    @html @view('people/affairs/subscriptions/index')(@)
    Ui.load_ui(@el)

  destroy: (e) ->
    if confirm(I18n.t('common.are_you_sure'))
      subscription = $(e.target).subscription()
      e.preventDefault()

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
    alert "an affair id is required" unless params.affair_id
    @affair_id = params.affair_id

    PersonAffairSubscription.url = =>
      "#{Spine.Model.host}/people/#{@person_id}/affairs/#{@affair_id}/subscriptions"

    PersonAffairSubscription.fetch()
    @new.render()
