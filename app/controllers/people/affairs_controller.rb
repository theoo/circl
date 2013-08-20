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

class People::AffairsController < ApplicationController

  layout false

  load_resource :person
  load_and_authorize_resource :through => :person

  monitor_changes :@affair

  def index

    @affairs = Affair.where("owner_id = ? OR buyer_id = ? OR receiver_id = ?", *([@person.id]*3)).uniq

    respond_to do |format|
      format.json { render :json => @affairs }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @affair.save
        format.json { render :json => @affair }
      else
        format.json { render :json => @affair.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @affair }
    end
  end

  def update
    respond_to do |format|
      if @affair.update_attributes(params[:affair])
        format.json { render :json => @affair }
      else
        format.json { render :json => @affair.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @affair.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @affair.errors, :status => :unprocessable_entity}
      end
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
