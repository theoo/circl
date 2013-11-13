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

class Settings::TaskTypesController < ApplicationController

  layout false

  load_and_authorize_resource

  def index

    @task_types = TaskType.actives

    respond_to do |format|
      format.json { render :json => @task_types }
    end
  end

  def everything

    @task_types = TaskType.all

    respond_to do |format|
      format.json { render :json => @task_types }
    end
  end

  def show
    edit
  end

  def create
    @task_type.value = params[:value]
    respond_to do |format|
      if @task_type.save
        format.json { render :json => @task_type }
      else
        format.json { render :json => @task_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @task_type }
    end
  end

  def update
    @task_type.value = params[:value]
    respond_to do |format|
      if @task_type.update_attributes(params[:task_type])
        format.json { render :json => @task_type }
      else
        format.json { render :json => @task_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @task_type.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @task_type.errors, :status => :unprocessable_entity}
      end
    end
  end

end
