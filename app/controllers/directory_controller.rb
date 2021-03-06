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

class DirectoryController < ApplicationController

  layout 'application'

  # FIXME this causes stranges persmissions with the name of methods from this helper
  include ApplicationHelper

  rescue_from Tire::Search::SearchRequestFailed do |error|
    # Indicate incorrect query to the user
    if error.message =~ /SearchParseException/ && params[:query]
      query = HashWithIndifferentAccess.new(JSON.parse(params[:query]))
      message = I18n.t('directory.errors.query_invalid', query: query[:search_string])
    else
      message = I18n.t('directory.errors.search_error', error: error.message)
    end

    if request.format.json?
      render json: { search_string: [message] }, status: :unprocessable_entity
    elsif request.format.html?
      flash[:error] = message
      redirect_to directory_path
    end
  end

  def index
    authorize! :index, Directory

    # In case this query redirect to a custom action after people selection.
    @custom_action = params[:custom_action] if params[:custom_action]

    # Set the query preset as a template for the current query
    if QueryPreset.count == 0
      @query = HashWithIndifferentAccess.new QueryPreset.new.query
    else
      @query = HashWithIndifferentAccess.new QueryPreset.reorder(:id).first.query
    end

    person = false

    if params[:query]

      # Merge the current query to the previously selected query preset template
      if params[:query].is_a? HashWithIndifferentAccess
        @query.merge!(HashWithIndifferentAccess.new(params[:query]))
      elsif params[:query].is_a? String
        @query.merge!(HashWithIndifferentAccess.new(JSON.parse(params[:query])))
      else
        raise ArgumentError, "invalid query".inspect
      end

      # Validates query
      if @query[:selected_attributes] and @query[:selected_attributes].size > 0
        if ! @query[:search_string].blank?
          @results_count = ElasticSearch::count(@query[:search_string])
        end
      else
        raise Tire::Search::SearchRequestFailed,
          I18n.t('directory.errors.you_need_to_select_at_least_one_attribute_to_display')
      end
    end

    # GON, preload some objects
    gon.push generic_templates: GenericTemplate.all.map(&:as_json)

    if params[:template_id] and request[:format] != 'csv'
      people = es_search.map{ |p| p.load }
      reference = people.first
      reference.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.html do
        if @results_count == 1 and not @custom_action
          person = es_search.first
          flash[:notice] = I18n.t("directory.notices.result_return_only_one_person")
          redirect_to person_path(person)
        else
          render
        end
      end

      format.json do
        render json: PeopleDatatable.new(view_context, @query, current_person)
      end

      format.js do
        render json: PeopleDatatable.new(view_context, @query, current_person), callback: params[:callback]
      end

      format.xml do
        render xml: people.to_xml
      end

      format.csv do
        peopl = es_search.map do |p|
          db_person = Person.find(p.id)
          structure = @query[:selected_attributes].each_with_object({}){|a,o| o[a] = ""}
          @query[:selected_attributes].each_with_object(OpenStruct.new(structure)) do |f, o|
            if db_person.respond_to? f
              o.send("#{f}=", relation_to_string(db_person.send(f)))
            else
              o.send("#{f}=", relation_to_string(p.send(f)))
            end
          end
        end
        render inline: csv_ify(peopl, @query['selected_attributes'])
      end

      format.pdf do
        @pdf = ""
        people = es_search.map!{ |p| p.load }
        generator = AttachmentGenerator.new(people, reference)
        generator.pdf { |o,pdf| @pdf = pdf.read }
        send_data @pdf, filename: "people.pdf", type: 'application/pdf'
      end

      format.odt do
        @odt = ""
        people = es_search.map!{ |p| p.load }
        generator = AttachmentGenerator.new(people, reference)
        generator.odt { |o,odt| @odt = odt.read }
        send_data @odt, filename: "people.odt", type: 'application/vnd.oasis.opendocument.text'
      end

    end
  end

  def mailchimp
    authorize! :mailchimp, Directory

    query = JSON.parse params[:query]
    query.symbolize_keys!

    if query[:search_string].blank?

      respond_to do |format|
        format.json do
          render json: { search_string: [I18n.t('activerecord.errors.messages.blank')] }, status: :unprocessable_entity
        end
        format.html do
          flash[:alert] = I18n.t("directory.errors.query_empty")
          redirect_to admin_path(anchor: 'tags')
        end
      end

    else

      # TODO provide a get/setter in MailchimpSession class
      if false # mailchimp_synchronizing?

        flash[:alert] = I18n.t('common.errors.already_synchronizing')

      else

        flash[:notice] = I18n.t('common.notices.synchronization_started', email: current_person.email)
        BackgroundTasks::SynchronizeMailchimp.schedule(
          person_id: current_person.id,
          list_id: params[:id],
          directory_query: query[:search_string]
          )

      end

      respond_to do |format|
        format.json { render json: {} }
        format.html { redirect_to directory_path }
      end

    end
  end

  def map
    authorize! :map, Directory

    @query = HashWithIndifferentAccess.new((QueryPreset.count == 0) ? QueryPreset.new.query : QueryPreset.order(:id).first.query)

    person = false

    if params[:query]
      @query.merge!(HashWithIndifferentAccess.new(JSON.parse(params[:query])))
      if @query[:selected_attributes] && @query[:selected_attributes].size > 0
        if ! @query[:search_string].blank?
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
          @map[:markers] << {latlng: [p.latitude, p.longitude], popup: popup}
        end
      end
      @map[:config] = Rails.configuration.settings["maps"]
    end

    respond_to do |format|
      format.html do
        render 'people/map' , layout: 'minimal'
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
          PrivateTag.create(name: tag)
        end
      end
      if params[:public_tags]
        params[:public_tags].each do |tag|
          PublicTag.create(name: tag)
        end
      end
      # Create missing jobs
      if params[:jobs]
        params[:jobs].each do |job|
          Job.create(name: job)
        end
      end

      # Temporarly disable geoloc and ES
      Rails.configuration.settings['maps']['enable_geolocalization'] = false
      Rails.configuration.settings['elasticsearch']['enable_indexing'] = false
      # Then re-parse file and import people
      report = Person.parse_people(session[:people_file_data])
      # raise ArgumentError, report[:people].map(&:comments_edited_by_others).inspect
      report[:people].each do |p|
        comments = p.comments_edited_by_others.map{|c| c.dup}
        p.comments_edited_by_others = []
        p.save
        comments.each do |c|
          c.resource = p
          c.person = current_person
          c.save!
        end

        # Reset people table id sequence
        last_id = Person.order(:id).last.id
        ActiveRecord::Base.connection.execute "SELECT setval('people_id_seq', #{last_id});"
      end

      # Ensure ES and geoloc are enable again
      Rails.configuration.settings['elasticsearch']['enable_indexing'] = true
      Rails.configuration.settings['maps']['enable_geolocalization'] = true


      # Reindex the whole database
      BackgroundTasks::RunRakeTask.schedule(name: 'elasticsearch:sync')
    end

    # Ensure ES and geoloc are enable again, whatever happend during transaction
    Rails.configuration.settings['elasticsearch']['enable_indexing'] = true
    Rails.configuration.settings['maps']['enable_geolocalization'] = true

    # In rails 3.1, session is a normal Hash
    # In rails 3.2, session is a CGI::Session
    begin
      session.delete(:people_file_data) # Rails 3.1
      session.data.delete(:people_file_data) # Rails 3.2
    rescue
    end

    PersonMailer.send_people_import_report(current_person, report[:people]).deliver
    flash[:notice] = I18n.t('directory.notices.people_imported', email: current_person.email)
    Activity.create!(person: current_person, resource_type: 'Admin', resource_id: '0', action: 'info', data: { people: "imported at #{Time.now}" })
    redirect_to directory_path
  end

  private

  # Effectively search in ES with the giver attributes
  def es_search
    if ! @query[:search_string].blank?
      ElasticSearch::search( @query[:search_string],
        @query[:selected_attributes],
        @query[:attributes_order],
        @current_person)
    end
  end

end
