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
      @query.merge!(HashWithIndifferentAccess.new(JSON.parse(params[:query])))
      if @query[:selected_attributes] && @query[:selected_attributes].size > 0
        if ! @query[:search_string].blank?
          # Check if query returns only one person and set person if so
          people = ElasticSearch::search( @query[:search_string],
                                          @query[:selected_attributes],
                                          @query[:attributes_order],
                                          @current_person)
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

      format.xml do
        people = ElasticSearch::search( @query[:search_string],
                                        @query[:selected_attributes],
                                        @query[:attributes_order],
                                        @current_person)
        people.map!{ |p| p.load }
        render :xml => people.to_xml
      end

      format.csv do
        # TODO make this nicer
        people = ElasticSearch::search( @query[:search_string],
                                        @query[:selected_attributes],
                                        @query[:attributes_order],
                                        @current_person)
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
      flash[:alert] = I18n.t('misc.mailchimp.already_synchronizing')
    else
      flash[:notice] = I18n.t('misc.mailchimp.synchronization_started', :email => current_person.email)
      BackgroundTasks::RunRakeTask.schedule(:name => 'mailchimp:sync',
                                            :arguments => { :person_id => current_person.id })
      Activity.create!(:person => current_person, :resource_type => 'Directory', :resource_id => '0', :action => 'info', :data => { :mailchimp => "Sync started at #{Time.now}" })
    end
    redirect_to directory_path
  end


  private

  def mailchimp_synchronizing?
    File.exists? Mailchimp::LOCK_FILE
  end

end
