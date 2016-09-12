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

class Settings::GenericTemplatesController < ApplicationController

  layout false

  load_and_authorize_resource

  def index
    respond_to do |format|
      format.json { render json: @generic_templates }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @generic_template }
      format.jpg do
        unless @generic_template.snapshot.path and File.exists? @generic_template.snapshot.path
          Templates::GenericThumbnails.perform(nil, ids: @generic_template.id)
          @generic_template.reload
        end
        redirect_to @generic_template.snapshot.url
      end
    end
  end

  def create
    @generic_template = GenericTemplate.new(generic_template_params)
    respond_to do |format|
      if @generic_template.save
        Templates::GenericThumbnails.perform(nil, ids: @generic_template.id)
        @generic_template.reload
        format.json { render json: @generic_template }
      else
        format.json { render json: @generic_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @generic_template }
      format.html { render layout: 'minimal' }
    end
  end

  def update
    respond_to do |format|
      if @generic_template.update_attributes(generic_template_params)
        Templates::GenericThumbnails.perform(nil, ids: @generic_template.id)
        @generic_template.reload
        format.json { render json: @generic_template }
        format.html do
          flash[:notice] = I18n.t("common.notices.successfully_updated")
          redirect_to edit_settings_template_path(@generic_template)
        end
      else
        format.json { render json: @generic_template.errors, status: :unprocessable_entity }
        format.html do
          flash[:error] = I18n.t("common.errors.failed_to_update")
          render 'edit'
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if @generic_template.destroy
        format.json { render json: {} }
      else
        format.json { render json: @generic_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def upload_odt
    authorize! :manage, GenericTemplate

    @generic_template = GenericTemplate.find params[:id]
    @generic_template.odt = params[:odt]

    respond_to do |format|
      if @generic_template.save
        Templates::GenericThumbnails.perform(nil, ids: @generic_template.id)
        format.json { render json: @generic_template }
      else
        format.json { render json: {errors: @generic_template.errors}, status: :unprocessable_entity }
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: GenericTemplate.count} }
    end
  end

  private

    def generic_template_params
      params.require(:generic_template).permit(
        :title,
        :snapshot,
        :created_at,
        :updated_at,
        :language_id,
        :class_name,
        :odt,
        :plural
      )
    end

end
