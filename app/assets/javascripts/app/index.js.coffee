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

  constructor: (params) ->
    super

    Ui.initialize_ui()

    # Don't display the hash fragment
    Spine.Route.setup(shim: true)


    # Start background tasks on every pages
    # App.BackgroundTaskRefreshInterval = 5000
    # background_tasks = new App.BackgroundTasks(el: "#background_tasks_counter", person_id: @person_id)

  subapp: (element, class_name, extra_params = {}) ->
    # TODO Raise a message if application controller cannot be found.
    # console.log "App." + class_name + " does not exist." unless "App." + class_name
    params = { el: element, person_id: @person_id }
    $.extend params, extra_params

    instance = eval "new App." + class_name + "(params)"
    element.data('controller', instance)
    instance.activate()

  @authenticity_token: -> $('meta[name="csrf-token"]').attr('content')

class @Dashboard extends App

  constructor: (params) ->
    super

    # everything depend on current user
    if params.id
      @person_id = params.id
      App.Person.fetch {id: @person_id}
    else
      console.log "params.id is missing"

    App.Person.one 'refresh', =>
      #@subapp($('#dashboard_messages'), 'DashboardMessages')
      @subapp($('#dashboard_timesheet'), 'DashboardTimesheet')
      @subapp($('#dashboard_comments'), 'DashboardComments')
      @subapp($('#dashboard_activity'), 'DashboardActivities')
      @subapp($('#dashboard_open_invoices'), 'DashboardOpenInvoices')
      @subapp($('#dashboard_current_affairs'), 'DashboardCurrentAffairs')
      @subapp($('#dashboard_last_people_added'), 'DashboardLastPeopleAdded')
      @subapp($('#dashboard_open_salaries'), 'DashboardOpenSalaries')
      # @subapp($('#dashboard_statistics'), 'DashboardStatistics')

class @PersonEdit extends App

  constructor: (params) ->
    super

    # everything depend on this person
    @person_id = params.id if params
    if @person_id
      # edit person
      App.Person.fetch {id: @person_id}
    else
      # new person
      @subapp($('#person'), 'People')

    App.Person.one 'refresh', =>
      @subapp($('#person'), 'People')
      @subapp($('#person_communication_languages'), 'PersonCommunicationLanguages')
      @subapp($('#person_translation_aptitudes'), 'PersonTranslationAptitudes')
      @subapp($('#person_private_tags'), 'PersonPrivateTags')
      @subapp($('#person_public_tags'), 'PersonPublicTags')
      @subapp($('#person_affairs'), 'PersonAffairs')
      @subapp($('#person_affair_task_rates'), 'PersonAffairTaskRates')
      @subapp($('#person_affair_tasks'), 'PersonAffairTasks')
      # @subapp($('#person_affair_products'), 'PersonAffairProducts')
      # @subapp($('#person_affair_extras'), 'PersonAffairExtras')
      @subapp($('#person_affair_subscriptions'), 'PersonAffairSubscriptions')
      @subapp($('#person_affair_invoices'), 'PersonAffairInvoices')
      @subapp($('#person_affair_receipts'), 'PersonAffairReceipts')
      @subapp($('#person_employment_contracts'), 'PersonEmploymentContracts')
      @subapp($('#person_salaries'), 'PersonSalaries')
      @subapp($('#person_salary_items'), 'PersonSalaryItems')
      @subapp($('#person_salary_tax_datas'), 'PersonSalaryTaxDatas')
      @subapp($('#person_roles'), 'PersonRoles')
      @subapp($('#person_comments'), 'PersonComments')
      @subapp($('#person_activities'), 'PersonActivities')

class @Directory extends App
  constructor: (params) ->
    super
    @subapp($('#directory_search_engine'), 'DirectorySearchEngine', params)

  # NOTE Use Directory.search(search_string: "something") to run a query in the directory
  @search: (query) =>
    window.location = @search_url(query)

  @search_url: (query) =>
    "/directory?query=#{@escape_query(query)}"

  @escape_query: (query) =>
    encodeURIComponent(JSON.stringify(query))

  # This method POST on directory#index the query and given options to build
  # a custom_action page. See SearchEngineController#Search for more informations.
  @search_with_custom_action: (query, options = {}) ->
    # The following options (* = required) are forwarded to directory#index
    form = $("<form action='/directory' method='post' id='directory_custom_action'>")
    query = $("<input type='hidden' name='query' value='#{JSON.stringify(query)}'>")
    # The given URL will be POSTed
    url = $("<input type='hidden' name='custom_action[url]' value=#{escape(options.url)}>")
    title = $("<input type='hidden' name='custom_action[title]' value=#{escape(options.title)}>")
    message = $("<input type='hidden' name='custom_action[message]' value=#{escape(options.message)}>")
    disabled = $("<input type='hidden' name='custom_action[disabled]' value=#{JSON.stringify(options.disabled)}>")
    auth_token = $("<input type='hidden' name='authenticity_token' value=#{@authenticity_token()}>")

    form.append query, url, title, message, disabled, auth_token

    $('body').append form

    form.submit()

class @Admin extends App

  constructor: (params) ->
    super

    # required by receipts and invoices widgets
    App.ApplicationSetting.fetch()

    @subapp($('#admin_private_tags'), 'AdminPrivateTags')
    @subapp($('#admin_public_tags'), 'AdminPublicTags')

    @subapp($('#admin_affairs'), 'AdminAffairs')
    @subapp($('#admin_subscriptions'), 'AdminSubscriptions')

    @subapp($('#admin_invoices'), 'AdminInvoices')
    @subapp($('#admin_receipts'), 'AdminReceipts')


class @Salaries extends App

  constructor: (params) ->
    super
    @subapp($('#salaries_salaries'), 'Salaries')
    @subapp($('#salaries_taxes'), 'SalariesTaxes')

class @Settings extends App

  constructor: (params) ->
    super

    @subapp($('#settings_locations'), 'SettingsLocations')
    @subapp($('#settings_languages'), 'SettingsLanguages')
    @subapp($('#settings_jobs'), 'SettingsJobs')

    @subapp($('#settings_invoice_templates'), 'SettingsInvoiceTemplates')
    @subapp($('#settings_salary_templates'), 'SettingsSalariesTemplates')

    @subapp($('#settings_search_attributes'), 'SettingsSearchAttributes')
    @subapp($('#settings_ldap_attributes'), 'SettingsLdapAttributes')
    @subapp($('#settings_roles'), 'SettingsRoles')
    @subapp($('#settings_role_permissions'), 'SettingsRolePermissions')

    @subapp($('#settings_task_types'), 'SettingsTaskTypes')
    @subapp($('#settings_task_rates'), 'SettingsTaskRates')

    @subapp($('#settings_application_settings'), 'SettingsApplicationSettings')
