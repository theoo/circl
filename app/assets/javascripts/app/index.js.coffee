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

# A nice place for extensions
Spine.Extensions = {}

class @App extends Spine.Controller

  # Global configuration
  @AVAILABLE_EXPORT_SYSTEMS = ['banana', 'csv']

  constructor: (params) ->
    super
    Ui.initialize_ui()

    # Don't display the hash fragment
    Spine.Route.setup(shim: true)

    # preload dependencies
    App.ApplicationSetting.one 'refresh', =>
      App.Currency.one 'refresh', =>
        @el.trigger "dependencies_preloaded"
      App.Currency.fetch()
    App.ApplicationSetting.fetch()

    @sub_nav = $("#sub_nav")
    @preload_models({'GenericTemplate': 'generic_templates'})

  subapp: (element, class_name, extra_params = {}) ->
    # TODO Raise a message if application controller cannot be found.
    # console.log "App." + class_name + " does not exist." unless "App." + class_name
    params = { el: element, person_id: @person_id }
    $.extend params, extra_params

    instance = eval "new App." + class_name + "(params)"
    element.data('controller', instance)
    instance.activate()

  # Arguments: Object {'ModelName': 'gon_collection_name'}
  preload_models: (models) ->
    for c,o of models
      App[c].refresh( eval(gon[o]), {clear: true} ) if gon[o]

  @authenticity_token: -> $('meta[name="csrf-token"]').attr('content')

  # Named user here to prevent confusion with person, which is the current
  # edited person.
  @current_user =
    JSON.parse($('meta[name="current_user"]').attr('content'))

  @available_currencies =
    JSON.parse($('meta[name="available_currencies"]').attr('content'))


class @Dashboard extends App

  constructor: (params) ->
    super

    @el.one 'dependencies_preloaded', =>
      # everything depend on current user
      if params.id
        @person_id = params.id
        App.Person.fetch {id: @person_id}
      else
        console.log "params.id is missing"

      App.Person.one 'refresh', =>
        #@subapp($('#dashboard_messages'), 'DashboardMessages')
        # @subapp($('#dashboard_shortcuts'), 'DashboardShortcuts')
        @subapp($('#dashboard_background_tasks'), 'DashboardBackgroundTasks')
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

    @el.one 'dependencies_preloaded', =>
      # everything depend on this person
      @person_id = params.id if params
      if @person_id
        # edit person
        App.Person.fetch {id: @person_id}
      else
        # new person
        @subapp($('#person'), 'People')
        Ui.load_tabs $(document)

      # And tabs content
      App.Person.one 'refresh', =>
        @sub_nav.one 'info', =>
          @subapp($('#person'), 'People')
          @subapp($('#person_communication_languages'), 'PersonCommunicationLanguages')
          @subapp($('#person_private_tags'), 'PersonPrivateTags')
          @subapp($('#person_public_tags'), 'PersonPublicTags')

        @sub_nav.one 'salaries', =>
          @subapp($('#person_employment_contracts'), 'PersonEmploymentContracts')
          @subapp($('#person_salaries_statistics'), 'PersonSalariesStatistics')

        @sub_nav.one 'permissions', =>
          @subapp($('#person_roles'), 'PersonRoles')

        @sub_nav.one 'activities', =>
          @subapp($('#person_comments'), 'PersonComments')
          @subapp($('#person_activities'), 'PersonActivities')

        App.GenericTemplate.one 'refresh', =>
          @sub_nav.one 'affairs', =>
            @subapp($('#person_affairs'), 'PersonAffairs')
            @subapp($('#person_affair_task_rates'), 'PersonAffairTaskRates')
            @subapp($('#person_affair_tasks'), 'PersonAffairTasks')
            @subapp($('#person_affair_products'), 'PersonAffairProducts')
            @subapp($('#person_affair_extras'), 'PersonAffairExtras')
            @subapp($('#person_affair_subscriptions'), 'PersonAffairSubscriptions')
            @subapp($('#person_affair_invoices'), 'PersonAffairInvoices')
            @subapp($('#person_affair_receipts'), 'PersonAffairReceipts')

          @sub_nav.one 'salaries', =>
            @subapp($('#person_salaries'), 'PersonSalaries')
            @subapp($('#person_salary_items'), 'PersonSalaryItems')
            @subapp($('#person_salary_tax_datas'), 'PersonSalaryTaxDatas')

          # add anchor to pagination so the tab remains the same.
          on_tab_change_callback = (e) ->
            $("#pagination a").each (index, el) ->
              anchor = location.hash.split('#')
              if anchor
                url = $(el).attr('href').split("#")[0]
                $(el).attr('href', [url, anchor[1]].join("#"))

          # Finally, load tabs
          Ui.load_tabs $(document), on_tab_change_callback

        App.GenericTemplate.fetch()

class @Directory extends App
  constructor: (params) ->
    super
    @el.one 'dependencies_preloaded', =>
      @subapp($('#directory_search_engine'), 'DirectorySearchEngine', params)

    @subapp($('#tag_cloud'), 'TagCloud', params)

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

    @el.one 'dependencies_preloaded', =>
      @sub_nav.one 'creditors', =>
        @subapp($('#admin_creditors'), 'AdminCreditors')

      @sub_nav.one 'tags', =>
        @subapp($('#admin_private_tags'), 'AdminPrivateTags')
        @subapp($('#admin_public_tags'), 'AdminPublicTags')

      @sub_nav.one 'products', =>
        @subapp($('#admin_product_orders'), 'AdminProductOrders')

      App.GenericTemplate.one 'refresh', =>
        @sub_nav.one 'affairs', =>
          @subapp($('#admin_affairs'), 'AdminAffairs')
          @subapp($('#admin_subscriptions'), 'AdminSubscriptions')
        @sub_nav.one 'finances', =>
          @subapp($('#admin_invoices'), 'AdminInvoices')
          @subapp($('#admin_receipts'), 'AdminReceipts')

        # Finally, load tabs
        Ui.load_tabs $(document)

      App.GenericTemplate.fetch()

class @Salaries extends App

  constructor: (params) ->
    super
    @sub_nav.one 'payroll', =>
      @subapp($('#salaries_salaries'), 'Salaries')
    @sub_nav.one 'deductions', =>
      @subapp($('#salaries_taxes'), 'SalariesTaxes')

    # Finally, load tabs
    Ui.load_tabs $(document)

class @Settings extends App

  constructor: (params) ->
    super

    @el.one 'dependencies_preloaded', =>
      @sub_nav.one 'properties', =>
        @subapp($('#settings_locations'), 'SettingsLocations')
        @subapp($('#settings_languages'), 'SettingsLanguages')
        @subapp($('#settings_jobs'), 'SettingsJobs')

      @sub_nav.one 'templates', =>
        @subapp($('#settings_invoice_templates'), 'SettingsInvoiceTemplates')
        @subapp($('#settings_generic_templates'), 'SettingsGenericTemplates')

      @sub_nav.one 'searchengine', =>
        @subapp($('#settings_search_attributes'), 'SettingsSearchAttributes')
        @subapp($('#settings_ldap_attributes'), 'SettingsLdapAttributes')
        @subapp($('#settings_mailchimp'), 'SettingsMailchimp')

      @sub_nav.one 'privileges', =>
        @subapp($('#settings_roles'), 'SettingsRoles')
        @subapp($('#settings_role_permissions'), 'SettingsRolePermissions')

      @sub_nav.one 'affairs', =>
        @subapp($('#settings_task_types'), 'SettingsTaskTypes')
        @subapp($('#settings_task_rates'), 'SettingsTaskRates')
        @subapp($('#settings_conditions'), 'SettingsConditions')

        @subapp($('#settings_products'), 'SettingsProducts')
        @subapp($('#settings_product_programs'), 'SettingsProductPrograms')

      @sub_nav.one 'currencies', =>
        @subapp($('#settings_currencies'), 'SettingsCurrencies')
        @subapp($('#settings_currency_rates'), 'SettingsCurrencyRates')

      @sub_nav.one 'advanced', =>
        @subapp($('#settings_application_settings'), 'SettingsApplicationSettings')

      # Finaly, load tabs
      Ui.load_tabs $(document)
