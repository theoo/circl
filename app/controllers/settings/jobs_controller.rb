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

class Settings::JobsController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@job

  def index
    respond_to do |format|
      format.json { render :json => @jobs }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @job.save
        format.json { render :json => @job }
      else
        format.json { render :json => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @job }
    end
  end

  def update
    respond_to do |format|
      if @job.update_attributes(params[:job])
        format.json { render :json => @job }
      else
        format.json { render :json => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @job.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @jobs.where("jobs.name ~* ?", param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.name}}}
    end
  end

end
