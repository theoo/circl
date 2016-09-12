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

class Settings::SearchAttributesController < ApplicationController
  layout false

  load_and_authorize_resource

  def index
    respond_to do |format|
      format.json { render json: @search_attributes.order(:id) }
    end
  end

  def searchable
    @search_attributes = @search_attributes.searchable

    respond_to do |format|
      format.json { render json: @search_attributes.as_json(except: [:mapping, :indexing]) }
    end
  end

  def show
    edit
  end

  def create
    @search_attribute = SearchAttribute.new(search_attribute_params)
    respond_to do |format|
      if @search_attribute.save
        format.json  { render json: @search_attribute }
      else
        format.json { render json: @search_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @search_attribute }
    end
  end

  def update
    respond_to do |format|
      if @search_attribute.update_attributes(search_attribute_params)
        format.json { render json: @search_attribute }
      else
        format.json { render json: @search_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @search_attribute.destroy
        format.json { render json: {} }
      else
        format.json { render json: @search_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  def synchronize
    if RunRakeTask.create(name: 'elasticsearch:sync')
      Activity.create!(person: current_person, resource_type: 'SearchAttribute', resource_id: '0', action: 'info', data: { synchronize: "Sync started at #{Time.now}" })
      flash[:notice] = I18n.t('common.notices.synchronization_started', email: current_person.email)
    else
      flash[:alert] = I18n.t('common.errors.already_synchronizing')
    end

    redirect_to settings_path, anchor: 'searchengine'
  end

  private

    def search_attribute_params
      params.require(:search_attribute).permit(
        :model,
        :name,
        :indexing,
        :mapping,
        :group
      )
    end

end
