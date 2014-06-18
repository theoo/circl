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

class Settings::LocationsController < ApplicationController

  layout false

  load_and_authorize_resource except: :index

  monitor_changes :@location

  def index
    authorize! :index, Location
    respond_to do |format|
      format.json { render json: LocationsDatatable.new(view_context) }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @location.save
        format.json { render json: @location }
      else
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @location }
    end
  end

  def update
    respond_to do |format|
      if @location.update_attributes(params[:location])
        format.json { render json: @location }
      else
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @location.destroy
        format.json { render json: {} }
      else
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    result = []
    unless params[:term].blank?
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      details = param.split(" ")

      # The expected format is ZIP(numeric) Location(alpha)
      if details.size > 1
        zip = details[0] if details[0].to_i != 0
        loc = details[1..-1].join(" ")
      end


      if zip and loc
        result = @locations.where("locations.postal_code_prefix ~* ? AND
                                   locations.name ~* ?",
                                   zip, loc).limit(50)


      else
        param = "^#{param}"
        result = @locations.where("locations.postal_code_prefix ~* ? OR
                                   locations.name ~* ?",
                                   *([param] * 2)).limit(50)
      end
    end

    respond_to do |format|
      format.json { render json: result.map{ |t| {id: t.id, label: t.full_name }}}
    end
  end

end
