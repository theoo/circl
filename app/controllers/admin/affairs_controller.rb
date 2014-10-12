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

class Admin::AffairsController < ApplicationController

  include ControllerExtentions::Affairs

  layout false

  load_and_authorize_resource except: :index

  def index
    authorize! :index, Affair
    respond_to do |format|
      format.json { render json: AffairsDatatable.new(view_context) }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to person_path(@affair.owner, anchor: "affairs/#{@affair.id}")}
      format.json { render json: @affair }
    end
  end

  # Search is in AffairsExtention

  def available_statuses
    a = Affair.available_statuses
    a.delete(nil)
    statuses = a.each_with_object({}) do |s, h|
      h[Affair.statuses_value_for(s).to_s] = s
    end

    respond_to do |format|
      format.json { render json: statuses }
    end
  end

end
