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

class People::TasksController < ApplicationController

  layout false

  load_resource :person
  load_and_authorize_resource :through => :person

  monitor_changes :@task

  def index
    respond_to do |format|
      format.json { render :json => @tasks }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @task.save
        format.json { render :json => @task }
      else
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @task }
    end
  end

  def update
    respond_to do |format|
      if @task.update_attributes(params[:task])
        format.json { render :json => @task }
      else
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @task.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @task.errors, :status => :unprocessable_entity}
      end
    end
  end

end
