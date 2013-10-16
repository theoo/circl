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

class @PersonEdit extends App

  constructor: (params) ->
    super

    # everything depend on this person
    @person_id = params.id
    App.Person.fetch {id: @person_id}

    App.Person.one 'refresh', =>
      @subapp($('#person'), 'People')
      @subapp($('#person_communication_languages'), 'PersonCommunicationLanguages')
      @subapp($('#person_translation_aptitudes'), 'PersonTranslationAptitudes')
      @subapp($('#person_private_tags'), 'PersonPrivateTags')
      @subapp($('#person_public_tags'), 'PersonPublicTags')
      @subapp($('#person_affairs'), 'PersonAffairs')
      @subapp($('#person_affair_subscriptions'), 'PersonAffairSubscriptions')
      # @subapp($('#person_affair_tasks'), 'PersonAffairTasks')
      # @subapp($('#person_affair_products'), 'PersonAffairProducts')
      # @subapp($('#person_affair_extras'), 'PersonAffairExtras')
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
    @subapp $('#directory_filters'),
            'DirectoryQueryPresets',
            {search: true, edit: false}

    @subapp($('#directory_search_engine'), 'DirectorySearchEngine')

  # NOTE Use Directory.search(search_string: "somthing") to run a query in the directory
  @search: (query) =>
    window.location = @search_url(query)

  @search_url: (query) =>
    "/directory?query=#{@escape_query(query)}"

  @escape_query: (query) =>
    encodeURIComponent(JSON.stringify(query))

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

    @subapp($('#settings_application_settings'), 'SettingsApplicationSettings')
