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

class Settings::Roles::PermissionsController < ApplicationController

  layout false

  load_resource :role
  load_and_authorize_resource through: :role

  def index
    respond_to do |format|
      format.json do
        render json: @permissions
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @permission.save
        format.json do
          render json: @permission
        end
      else
        format.json { render json: @permission.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @permission }
    end
  end

  def update
    respond_to do |format|
      if @permission.update_attributes(params[:permission])
        format.json do
          render json: @permission
        end
      else
        format.json { render json: @permission.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @permission.destroy
        format.json { render json: {} }
      else
        format.json { render json: @permission.errors, status: :unprocessable_entity }
      end
    end
  end

end
