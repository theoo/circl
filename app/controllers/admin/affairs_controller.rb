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

  layout false

  load_and_authorize_resource :except => :index

  def index
    authorize! :index, Affair
    respond_to do |format|
      format.json { render :json => AffairsDatatable.new(view_context) }
    end
  end

  def show
    respond_to do |format|
      format.json { render :json => @affair }
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @affairs.where("affairs.title #{SQL_REGEX_KEYWORD} ?", param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.title}}}
    end
  end

end
