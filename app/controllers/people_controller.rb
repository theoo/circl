=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class PeopleController < ApplicationController

  load_and_authorize_resource except: :welcome

  monitor_changes :@person, only: [:create, :update, :update_password, :destroy]

  layout false

  def index
    respond_to do |format|
      format.html { redirect_to directory_path }
      format.json { render json: {}, status: :unprocessable_entity }
    end
  end

  def show

    if params[:template_id]
      @person.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.html do
        gon.archived_affairs_count = @person.affairs.real_archived.count
        render layout: 'application'
      end

      format.json do
        options = {}
        options[:restricted_attributes] = can?(:restricted_attributes, @person)
        options[:authenticate_using_token] = can?(:authenticate_using_token, @person)

        render json: @person.as_json(options)
      end

      format.pdf do
        @pdf = ""
        generator = AttachmentGenerator.new(@person)
        generator.pdf { |o,pdf| @pdf = pdf.read }
        send_data @pdf,
                  filename: "person_#{params[:person_id]}.pdf",
                  type: 'application/pdf'
      end

      format.odt do
        @odt = ""
        generator = AttachmentGenerator.new(@person)
        generator.odt { |o,odt| @odt = odt.read }
        send_data @odt,
                  filename: "person_#{params[:person_id]}.odt",
                  type: 'application/vnd.oasis.opendocument.text'
      end

    end
  end

  def map

    @map = {}

    @map[:title] = "<b>"
    @map[:title] += @person.name
    @map[:title] += "</b>, "
    @map[:title] += @person.full_address_inline

    popup = "<b>"
    popup += @person.name
    popup += "</b><br />"
    popup += @person.full_address.split("\n").join("<br />")

    if @person.latitude and @person.longitude
      @map[:markers] = [{latlng: [@person.latitude, @person.longitude], popup: popup}]
    else
      @placeholder = Person.find ApplicationSetting.value("me")
      if @placeholder.latitude
        latlng = [@placeholder.latitude, @placeholder.longitude]
      else
        latlng = [46.1995684109777, 6.13489329814911]
      end
      @map[:markers] = [{latlng: latlng, popup: popup}]
    end
    @map[:config] = Rails.configuration.settings["maps"]

    respond_to do |format|
      format.html { render layout: 'minimal' }
    end
  end

  def new
    respond_to do |format|
      format.html { render layout: 'application', action: 'show' }
      format.json { render json: @person }
    end
  end

  def create

    find_or_create_job
    validates_permissions_on_params

    # FIXME: strange behavior here, callbacks before_save not working so I have to force it to nil (cancan set it to "")
    @person.authentication_token = nil unless params[:generate_authentication_token]

    respond_to do |format|
      if @person.save
        flash.notice = I18n.t("person.notices.successfully_created_explanation", name: @person.name)
        format.json { render json: @person }
      else
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def update

    find_or_create_job
    validates_permissions_on_params

    respond_to do |format|
      if @person.update_attributes(person_params)
        format.json do
          options = {}
          options[:restricted_attributes] = can?(:restricted_attributes, @person)
          options[:authenticate_using_token] = can?(:authenticate_using_token, @person)

          render json: @person.as_json(options)
        end
      else
        format.json { render json: @person.errors, status: :unprocessable_entity}
      end
    end
  end

  def destroy
    respond_to do |format|
      if @person == current_person
        format.html do
          flash[:alert] = I18n.t('person.errors.hey_you_cannot_suicide')
          render :show, layout: 'application'
        end
        format.json do
          flash[:alert] = I18n.t('person.errors.hey_you_cannot_suicide')
          render json: @person.errors, status: :unprocessable_entity
        end
      else
        if @person.destroy
          format.html do
            flash[:notice] = I18n.t('common.notices.successfully_destroyed')
            # TODO Require Tire update to elasticsearch-ruby gem first
            # if request.referer.match("paginate")
            #   redirect_to request.referer
            # else
            redirect_to directory_path
            # end
          end
          format.json { render json: {} }
        else
          format.html do
            # TODO usually if we reach this code path it's because ldap_remove fails
            # in the before_destroy callback. Refactor so Person#errors is updated with the reasons.
            flash[:alert] = I18n.t('common.errors.failed_to_destroy')
            render :show, layout: 'application'
          end
          format.json do
            flash[:alert] = I18n.t('common.errors.failed_to_destroy') + " " + I18n.t("common.errors.please_verify_rights_and_record")
            render json: @person.errors, status: :unprocessable_entity
          end
        end
      end
    end
  end

  def welcome
    # this methods gathers first requests and redirect
    # to the dashboard with it's current_person params.
    # this redirection should not be possible through routes.rb

    #redirect_to dashboard_person_path(current_person)
    if can? :dashboard_index, current_person
      redirect_to person_dashboard_index_path(current_person)
    else
      redirect_to person_path(current_person)
    end
  end

  def change_password
    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  def update_password
    current_password = params[:person].delete(:current_password)
    if @person == current_person && !@person.valid_password?(current_password)
      @person.errors.add(:current_password, I18n.t('person.errors.invalid_current_password'))
      @person.assign_attributes person_params
    end

    respond_to do |format|
      if @person.errors.empty? && @person.update_attributes(person_params)
        format.html { redirect_to person_path(@person) }
      else
        format.html { render 'change_password', layout: 'application' }
      end
    end
  end

  def unlock
    @person.unlock_access!

    flash[:notice] = I18n.t("devise.views.account_unlocked")
    respond_to do |format|
      format.html { redirect_to person_path(@person) }
    end
  end

  # TODO do not redirect to show view if @person doesn't exists!
  def paginate
    # Parse query
    unless params[:query] && params[:query].is_a?(ActiveSupport::HashWithIndifferentAccess)
      params[:query] = HashWithIndifferentAccess.new(JSON.parse(params[:query]))
    end

    # The goal of this search is to get an array of 3 persons (before, displayed, after)
    @index = params[:index].to_i
    @query = params[:query]

    # Setup pagination if not yet
    session[:pagination] ||= {}
    session[:pagination][:query] ||= @query
    unless session[:pagination][:query_result]
      result = ElasticSearch::search(
        @query[:search_string],
        @query[:selected_attributes],
        @query[:attributes_order],
        @current_person)
      session[:pagination][:query_result] = result.map(&:id)
    end

    # Try to search from the person before unless it's the first entry
    from = (@index > 0) ? (@index - 1) : @index
    ids = session[:pagination][:query_result].values_at(from, from + 1, from + 2)
    @total_entries = session[:pagination][:query_result].size

    # If it's the first entry, modify array so there's nobody before
    ids.unshift(nil) if @index == 0

    # Person.where(id: ids).to_a won't return nil for a nil id (array size will be only two items)
    @before, @person, @after = ids.map{|id| Person.find(id) if Person.exists?(id)}

    respond_to do |format|
      format.html do
        render :show, layout: 'application'
      end
    end
  end

  def search
    params[:options] ||= []

    if params[:term].blank?
      results = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      # Check if it's an email
      if param.match(/.*@.*/)
        results = @people.where("people.email ~* ? OR people.second_email ~* ?", param, param)
      elsif param.is_i?
        results = @people.where("people.id = ?", param)
      else
        # Check if it looks like a first/last name pair
        s = param.match(/([[:alpha:]]+)\s+([a-zA-Z]+)/)
        if s and s.size == 3
          results = @people.where("people.first_name ~* ? AND
                                  people.last_name ~* ?",
                                  s[1], s[2])
        else
          results = @people.where("people.first_name ~* ? OR
                                  people.last_name ~* ? OR
                                  people.organization_name ~* ? OR
                                  people.alias_name ~* ?",
                                  *([param] * 4))
        end
      end
      results.limit(10)
    end

    a = results.map do |p|
      h = { label: p.name, desc: p.full_address, id: p.id, affairs_count: p.affairs.alive.count }
      h[:title] = p.full_name if p.is_an_organization

      if params[:options].index("creditor_accounts")
        h[:creditor_account]              = p.creditor_account
        h[:creditor_transitional_account] = p.creditor_transitional_account
        h[:creditor_discount_account]     = p.creditor_discount_account
        h[:creditor_vat_account]          = p.creditor_vat_account
        h[:creditor_vat_discount_account] = p.creditor_vat_discount_account
      end

      h
    end

    respond_to do |format|
      format.json { render json: a}
    end
  end

  def title_search
    if params[:term].blank?
      result = []
    else
      result = @people.where("people.title ~* ?", params[:term])
        .select("DISTINCT(people.title)")
    end

    respond_to do |format|
      format.json { render json: result.map{|t| {label: t.title}}}
    end
  end

  def nationality_search
    if params[:term].blank?
      result = []
    else
      result = @people.where("people.nationality ~* ?", params[:term]).map{ |p| p.nationality }.uniq
    end

    respond_to do |format|
      format.json { render json: result.map{|t| {label: t}}}
    end
  end

  def duplicates_report
    @report = []
    Person.duplicates.each do |p|
      @report << Person.where(first_name: p.first_name, last_name: p.last_name)
    end

    respond_to do |format|
      format.html { } # TODO

      format.json do
        render json: @report
      end

      format.csv do
        render inline: csv_ify(@report.flatten,
          [:id, :first_name, :last_name, :email, :phone, :address,
            'location.try(:postal_code_prefix)', 'location.try(:name)',
            'private_tags.map{|t| t.name}.join(", ")', 'public_tags.map{|t| t.name}.join(", ")'])
      end
    end
  end

  private

    def find_or_create_job
      if params[:job]
        if params[:job][:name].blank?
          params[:job_id] = nil
        else
          # TODO I suggest we remove this and let admins create jobs before they edit people
          job = Job.find_or_create_by_name(params[:job][:name])
          params[:job_id] = job.id
        end
      end
    end

    def validates_permissions_on_params

      unless can?(:restricted_attributes, @person)
        Person::RESTRICTED_ATTRIBUTES.each { |s| person_params.delete(s) }
      end

      if can?(:authenticate_using_token, @person) and params[:generate_authentication_token]
        params[:renew_authentication_token] = true
      end
    end

    def person_params
      params
        .require(:person)
        .permit(
        :address,
        :address_for_bvr,
        :authentication_token,
        :avs_number,
        :bank_informations,
        :birth_date,
        :communication_language_ids,
        :created_at,
        :email,
        :errors,
        :first_name,
        :gender,
        :renew_authentication_token,
        :geographic_coordinates,
        :hidden,
        :id,
        :is_an_organization,
        :job_id,
        :last_name,
        :latitude,
        :location_id,
        :longitude,
        :main_communication_language_id,
        :mobile,
        :fax_number,
        :nationality,
        :organization_name,
        :phone,
        :second_email,
        :second_phone,
        :task_rate_id,
        :title,
        :updated_at,
        :website,
        :alias_name,
        :current_password,
        :password,
        :password_confirmation,
        :creditor_transitional_account,
        :creditor_account,
        :creditor_discount_account,
        :creditor_vat_account,
        :creditor_vat_discount_account
        )
    end

end
