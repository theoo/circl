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

class Settings::ApplicationSettingsController < ApplicationController

  layout false

  load_and_authorize_resource

  def index
    default_currency = ApplicationSetting.value("default_currency")
    if Currency.where(iso_code: default_currency).count > 0
      h = { key: 'default_currency_details', value: Currency.where(iso_code: default_currency).first.attributes.to_json }
      @application_settings << h
    end

    respond_to do |format|
      format.json { render json: @application_settings }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @application_setting.save
        format.json { render json: @application_setting }
      else
        format.json { render json: @application_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @application_setting }
    end
  end

  def update
    respond_to do |format|
      if @application_setting.update_attributes(params[:application_setting])
        format.json { render json: @application_setting }
      else
        format.json { render json: @application_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @application_setting.destroy
        format.json { render json: {} }
      else
        format.json { render json: @application_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  def restart
    # Touch and wait...
    FileUtils.touch([Rails.root, "tmp/restart.txt"]).join("/")
    flash[:notice] = I18n.t("application_setting.notices.application_restarted")

    respond_to do |format|
      format.html { redirect_to settings_path(anchor: :advanced) }
    end
  end

end
