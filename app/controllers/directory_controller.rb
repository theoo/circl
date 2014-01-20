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

require 'mailchimp/process'

class DirectoryController < ApplicationController

  layout 'application'

  # FIXME this causes stranges persmissions with the name of methods from this helper
  include ApplicationHelper

  rescue_from Tire::Search::SearchRequestFailed do |error|
    # Indicate incorrect query to the user
    if error.message =~ /SearchParseException/ && params[:query]
      query = HashWithIndifferentAccess.new(JSON.parse(params[:query]))
      message = I18n.t('directory.errors.query_invalid', :query => query[:search_string])
    else
      message = I18n.t('directory.errors.search_error', :error => error.message)
    end

    if request.format.json?
      render :json => { :search_string => [message] }, :status => :unprocessable_entity
    elsif request.format.html?
      flash[:error] = message
      redirect_to directory_path
    end
  end

  def index
    authorize! :index, Directory

    @custom_action = params[:custom_action] if params[:custom_action]

    @query = HashWithIndifferentAccess.new((QueryPreset.count == 0) ? QueryPreset.new.query : QueryPreset.order(:id).first.query)

    person = false

    if params[:query]

      if params[:query].is_a? HashWithIndifferentAccess
        @query.merge!(HashWithIndifferentAccess.new(params[:query]))
      elsif params[:query].is_a? String
        @query.merge!(HashWithIndifferentAccess.new(JSON.parse(params[:query])))
      else
        raise ArgumentError, "invalid query".inspect
      end

      if @query[:selected_attributes] and @query[:selected_attributes].size > 0
        if ! @query[:search_string].blank?
          people = ElasticSearch::search( @query[:search_string],
                                          @query[:selected_attributes],
                                          @query[:attributes_order],
                                          @current_person)

          # Check if query returns only one person and set person if so
          if people.size == 1
            person = people.first.load
          end
          @results_count = ElasticSearch::count(@query[:search_string])
        end
      else
        raise Tire::Search::SearchRequestFailed, I18n.t('directory.errors.you_need_to_select_at_least_one_attribute_to_display')
      end

    end

    respond_to do |format|
      format.html do
        if person and not @custom_action
          flash[:notice] = I18n.t("directory.notices.result_return_only_one_person")
          redirect_to person_path(person)
        else
          render
        end
      end

      format.json do
        render :json => PeopleDatatable.new(view_context, @query, current_person)
      end

      format.js do
        render :json => PeopleDatatable.new(view_context, @query, current_person), :callback => params[:callback]
      end

      format.xml do
        people.map!{ |p| p.load }
        render :xml => people.to_xml
      end

      format.csv do
        people = people.map do |p|
          @query[:selected_attributes].each_with_object(OpenStruct.new(p.to_hash)) do |f, o|
            o.send("#{f}=", relation_to_string(o.send(f)))
          end
        end
        render :inline => csv_ify(people, @query['selected_attributes'])
      end
    end
  end

  def mailchimp
    authorize! :mailchimp, Directory

    if mailchimp_synchronizing?
      flash[:alert] = I18n.t('common.errors.already_synchronizing')
    else
      flash[:notice] = I18n.t('common.notices.synchronization_started', :email => current_person.email)
      BackgroundTasks::RunRakeTask.schedule(:name => 'mailchimp:sync',
                                            :arguments => { :person_id => current_person.id })
      Activity.create!(:person => current_person, :resource_type => 'Directory', :resource_id => '0', :action => 'info', :data => { :mailchimp => "Sync started at #{Time.now}" })
    end
    redirect_to directory_path
  end

  def map
    authorize! :map, Directory

    @query = HashWithIndifferentAccess.new((QueryPreset.count == 0) ? QueryPreset.new.query : QueryPreset.order(:id).first.query)

    person = false

    if params[:query]
      @query.merge!(HashWithIndifferentAccess.new(JSON.parse(params[:query])))
      if @query[:selected_attributes] && @query[:selected_attributes].size > 0
        if ! @query[:search_string].blank?
          # Check if query returns only one person and set person if so
          people = ElasticSearch::search( @query[:search_string],
                                          @query[:selected_attributes],
                                          @query[:attributes_order],
                                          @current_person)
          @results_count = ElasticSearch::count(@query[:search_string])
        end
      else
        raise Tire::Search::SearchRequestFailed, I18n.t('directory.errors.you_need_to_select_at_least_one_attribute_to_display')
      end

    end

    @map = {}

    latitudes = people.map(&:latitude)
    latitudes.delete(nil)
    longitudes = people.map(&:longitude)
    longitudes.delete(nil)

    @map[:title] = @query[:search_string]
    if latitudes
      @map[:markers] = []
      people.map do |p|
        if p.latitude
          popup = "<b>"
          popup += p.name.to_s
          popup += "</b><br />"
          popup += [p.address, p.npa_town, p.country].join("<br />")
          @map[:markers] << {:latlng => [p.latitude, p.longitude], :popup => popup}
        end
      end
      @map[:config] = Rails.configuration.settings["maps"]
    end

    respond_to do |format|
      format.html do
        render 'people/map' , :layout => 'minimal'
      end
    end
  end

  def confirm_people
    authorize! :confirm_people, Directory

    unless params[:people_file]
      flash[:alert] = I18n.t('directory.errors.no_file_submitted')
      redirect_to admin_path
      return
    end

    session[:people_file_data] = params[:people_file].read
    @infos = Person.parse_people(session[:people_file_data])

    respond_to do |format|
      format.html { render }
    end
  end

  def import_people
    authorize! :import_people, Directory

    report = {}

    Person.transaction do
      # Create tags first
      if params[:private_tags]
        params[:private_tags].each do |tag|
          PrivateTag.create(:name => tag)
        end
      end
      if params[:public_tags]
        params[:public_tags].each do |tag|
          PublicTag.create(:name => tag)
        end
      end

      # Then re-parse file and import people
      report = Person.parse_people(session[:people_file_data])
      # TODO Import without ES indexation and reindex people after transaction
      report[:people].each do |p|
        p.save
      end
    end

    # In rails 3.1, session is a normal Hash
    # In rails 3.2, session is a CGI::Session
    begin
      session.delete(:people_file_data) # Rails 3.1
      session.data.delete(:people_file_data) # Rails 3.2
    rescue
    end

    PersonMailer.send_people_import_report(current_person, report[:people]).deliver
    flash[:notice] = I18n.t('directory.notices.people_imported', :email => current_person.email)
    Activity.create!(:person => current_person, :resource_type => 'Admin', :resource_id => '0', :action => 'info', :data => { :people => "imported at #{Time.now}" })
    redirect_to directory_path
  end

  private

  def mailchimp_synchronizing?
    File.exists? Mailchimp::LOCK_FILE
  end

end
