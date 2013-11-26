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

  load_and_authorize_resource :except => :welcome

  monitor_changes :@person, :only => [:create, :update, :update_password, :destroy]

  layout false

  def index
    respond_to do |format|
      format.html { redirect_to directory_path }
      format.json { render :json => {}, :status => :unprocessable_entity }
    end
  end

  def show
    respond_to do |format|
      format.html { render :layout => 'application' }
      format.json do
        options = {}
        options[:restricted_attributes] = can?(:restricted_attributes, @person)
        options[:authenticate_using_token] = can?(:authenticate_using_token, @person)

        render :json => @person.as_json(options)
      end
    end
  end

  def map

    if @person.latitude and @person.longitude
      popup = "<b>"
      popup += @person.name
      popup += "</b><br />"
      popup += @person.full_address.split("\n").join("<br />")
      @markers = [{:latlng => [@person.latitude, @person.longitude], :popup => popup}]
      @config = Rails.configuration.settings["maps"]
    end

    respond_to do |format|
      format.html { render :layout => 'minimal' }
    end
  end

  def new
    respond_to do |format|
      format.html { render :layout => 'application', :action => 'show' }
      format.json { render :json => @person }
    end
  end

  def create

    check_and_update_attributes

    # FIXME: strange behavior here, callbacks before_save not working so I have to force it to nil (cancan set it to "")
    @person.authentication_token = nil unless params[:person][:generate_authentication_token]

    respond_to do |format|
      if @person.save
        format.json { render :json => @person }
      else
        format.json { render :json => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    check_and_update_attributes

    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.json do
          options = {}
          options[:restricted_attributes] = can?(:restricted_attributes, @person)
          options[:authenticate_using_token] = can?(:authenticate_using_token, @person)

          render :json => @person.as_json(options)
        end
      else
        format.json { render :json => @person.errors, :status => :unprocessable_entity}
      end
    end
  end

  def destroy
    respond_to do |format|
      if @person.destroy
        format.html do
          flash[:notice] = I18n.t('common.notices.successfully_destroyed')
          redirect_to directory_path
        end
        format.json { render :json => {} }
      else
        format.html do
          # TODO usually if we reach this code path it's because ldap_remove fails
          # in the before_destroy callback. Refactor so Person#errors is updated with the reasons.
          flash[:alert] = I18n.t('common.errors.failed_to_destroy')
          render :show, :layout => 'application'
        end
        format.json do
          flash[:alert] = I18n.t('common.errors.failed_to_destroy') + " " + I18n.t("common.errors.please_verify_rights_and_record")
          render :json => @person.errors, :status => :unprocessable_entity
        end
      end
    end
  end

  def welcome
    # this methods gathers first requests and redirect
    # to the dashboard with it's current_person params.
    # this redirection should not be possible through routes.rb

    #redirect_to dashboard_person_path(current_person)
    redirect_to person_dashboard_index_path(current_person)
  end

  def change_password
    respond_to do |format|
      format.html { render :layout => 'application' }
    end
  end

  def update_password
    current_password = params[:person].delete(:current_password)
    if @person == current_person && !@person.valid_password?(current_password)
      @person.errors.add(:current_password, I18n.t('person.errors.invalid_current_password'))
      @person.assign_attributes params[:person]
    end

    respond_to do |format|
      if @person.errors.empty? && @person.update_attributes(params[:person])
        format.html { redirect_to person_path(@person) }
      else
        format.html { render 'change_password', :layout => 'application' }
      end
    end
  end

  def paginate 
    unless params[:query] && params[:query].is_a?(ActiveSupport::HashWithIndifferentAccess)
      params[:query] = HashWithIndifferentAccess.new(JSON.parse(params[:query]))
    end

    # The goal of this search is to get an array of 3 persons (before, displayed, after)
    @query = params[:query]
    @index = params[:index].to_i

    # Try to search from the person before unless it's the first entry
    @from = (@index > 0) ? (@index - 1) : @index
    results = ElasticSearch::search_paginated(@query[:search_string], @query[:selected_attributes], @query[:attributes_order], @from, 3, @current_person)
    @total_entries = results.total_entries
    results = results.to_a

    # If it's the first entry, modify array so there's nobody before
    results.unshift(nil) if @index == 0

    @before, @person, @after = results.map{ |p| p.load if p }

    respond_to do |format|
      format.html do
        render :show, :layout => 'application'
      end
    end
  end

  def search
    if params[:term].blank?
      results = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      results = @people.where("people.first_name #{SQL_REGEX_KEYWORD} ? OR
                              people.last_name #{SQL_REGEX_KEYWORD} ? OR
                              people.organization_name #{SQL_REGEX_KEYWORD} ?",
                              *([param] * 3)).limit(50)
    end

    respond_to do |format|
      format.json { render :json => results.map{ |p| { :label => p.name, :id => p.id }}}
    end
  end

  def title_search
    if params[:term].blank?
      result = []
    else
      result = @people.where("people.title #{SQL_REGEX_KEYWORD} ?", params[:term])
        .select("DISTINCT(people.title)")
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:label => t.title}}}
    end
  end

  def nationality_search
    if params[:term].blank?
      result = []
    else
      result = @people.where("people.nationality #{SQL_REGEX_KEYWORD} ?", params[:term]).map{ |p| p.nationality }.uniq
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:label => t}}}
    end
  end

  private

  def check_and_update_attributes
    if params[:job]
      if params[:job][:name].blank?
        params[:person][:job_id] = nil
      else
        # TODO I suggest we remove this and let admins create jobs before they edit people
        job = Job.find_or_create_by_name(params[:job][:name])
        params[:person][:job_id] = job.id
      end
    end

    unless can?(:restricted_attributes, @person)
      Person::RESTRICTED_ATTRIBUTES.each { |s| params[:person].delete(s) }
    end

    if can?(:authenticate_using_token, @person) and params[:generate_authentication_token]
      params[:person][:renew_authentication_token] = true
    end
  end

end
