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

#= require json2
#= require jquery
#= require underscore
#= require spine
#= require spine/manager
#= require spine/ajax
#= require spine/route
#= require spine/relation

#= require_self
#= require_tree ./lib
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views

class @App extends Spine.Controller

  @search_query: (query) =>
    window.location = @directory_url(query)

  @directory_url: (query) =>
    "/directory?query=#{@escape_query(query)}"

  @escape_query: (query) =>
    encodeURIComponent(JSON.stringify(query))

  constructor: (params) ->
    super

    Ui.initialize_ui()

    # Don't display the hash fragment
    Spine.Route.setup(shim: true)

    # Start background tasks on every pages
    App.BackgroundTaskRefreshInterval = 5000
    background_tasks = new App.BackgroundTasks(el: "#background_tasks_counter", person_id: @person_id)

  subapp: (element, class_name) ->
    # TODO Raise a message if application controller cannot be found.
    # console.log "App." + class_name + " does not exist." unless "App." + class_name
    instance = eval "new App." + class_name + "({el: element, person_id: this.person_id})"
    element.bind 'unload-panel', -> instance.deactivate()
    element.bind 'load-panel', -> instance.activate()

class @PersonEdit extends App

  constructor: (params) ->
    super

    @person_id = params.id

    @subapp($('#person'), 'People')
    # @subapp($('#person_activities'), 'PersonActivities')
    # @subapp($('#person_histories'), 'PersonHistories')
    # @subapp($('#person_affairs'), 'PersonAffairs')
    @subapp($('#person_comments'), 'PersonComments')
    # @subapp($('#person_communication_languages'), 'PersonCommunicationLanguages')
    # @subapp($('#person_employment_contracts'), 'PersonEmploymentContracts')
    @subapp($('#person_private_tags'), 'PersonPrivateTags')
    @subapp($('#person_public_tags'), 'PersonPublicTags')
    # @subapp($('#person_roles'), 'PersonRoles')
    # @subapp($('#person_salaries'), 'PersonSalaries')
    # @subapp($('#person_tasks'), 'PersonTasks')
    # @subapp($('#person_translation_aptitudes'), 'PersonTranslationAptitudes')

class @Admin extends App

  constructor: (params) ->
    super

    # required by receipts and invoices widgets
    App.ApplicationSetting.fetch()

    @subapp($('#admin_affairs'), 'AdminAffairs')
    @subapp($('#admin_invoices'), 'AdminInvoices')
    @subapp($('#admin_private_tags'), 'AdminPrivateTags')
    @subapp($('#admin_public_tags'), 'AdminPublicTags')
    @subapp($('#admin_receipts'), 'AdminReceipts')
    @subapp($('#admin_subscriptions'), 'AdminSubscriptions')

class @Salaries extends App

  constructor: (params) ->
    super
    @subapp($('#salaries_salaries'), 'SalariesSalaries')
    @subapp($('#salaries_taxes'), 'SalariesTaxes')
    @subapp($('#salaries_salary_templates'), 'SalariesTemplates')

class @Settings extends App

  constructor: (params) ->
    super

    @subapp($('#settings_application_settings'), 'SettingsApplicationSettings')
    @subapp($('#settings_invoice_templates'), 'SettingsInvoiceTemplates')
    @subapp($('#settings_jobs'), 'SettingsJobs')
    @subapp($('#settings_languages'), 'SettingsLanguages')
    @subapp($('#settings_ldap_attributes'), 'SettingsLdapAttributes')
    @subapp($('#settings_locations'), 'SettingsLocations')
    @subapp($('#settings_roles'), 'SettingsRoles')
    @subapp($('#settings_search_attributes'), 'SettingsSearchAttributes')
