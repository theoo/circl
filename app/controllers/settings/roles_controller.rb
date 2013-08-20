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

class Settings::RolesController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@role

  def index
    respond_to do |format|
      format.json do
        roles = @roles.map do |role|
          role.as_json.merge('members_count' => role.people.count)
        end
        render :json => roles
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @role.save
        format.json do
          render :json => @role.as_json.merge('members_count' => @role.people.count)
        end
      else
        format.json { render :json => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @role }
    end
  end

  def update
    respond_to do |format|
      if @role.update_attributes(params[:role])
        format.json do
          render :json => @role.as_json.merge('members_count' => @role.people.count)
        end
      else
        format.json { render :json => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @role.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

end
