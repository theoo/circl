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

class Admin::PublicTagsController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@public_tag

  def index
    respond_to do |format|
      format.json { render :json => @public_tags }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @public_tag.save
        format.json { render :json => @public_tag }
      else
        format.json { render :json => @public_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @public_tag }
    end
  end

  def update
    respond_to do |format|
      if @public_tag.update_attributes(params[:public_tag])
        format.json { render :json => @public_tag }
      else
        format.json { render :json => @public_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @public_tag.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @public_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @public_tags.where("public_tags.name #{SQL_REGEX_KEYWORD} ?", param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.name}}}
    end
  end

  def add_members
    respond_to do |format|
      query = JSON.parse params[:query]
      query.symbolize_keys!
      if query[:search_string].blank?
        format.json { render :json => { :search_string => [I18n.t('activerecord.errors.messages.blank')] }, :status => :unprocessable_entity }
      else
        new_people_array = ElasticSearch.search(query[:search_string], query[:selected_attributes], query[:attributes_order]).map(&:id)
        current_people_array = @public_tag.people.map(&:id)
        @public_tag.people = Person.where(:id => [current_people_array, new_people_array].flatten.uniq)
        format.json { render :json => {} }
        format.html do
          # TODO improve report
          flash[:notice] = I18n.t("tag.notices.members_added", :members_count => new_people_array.count)
          redirect_to admin_path(:anchor => 'tags')
        end
      end
    end
  end

  def remove_all_members
    respond_to do |format|
      if @public_tag.people = []
        format.json { render :json => {} }
      else
        format.json { render :json => { :search_string => [I18n.t('activerecord.errors.messages.blank')] }, :status => :unprocessable_entity }
      end
    end
  end

end
