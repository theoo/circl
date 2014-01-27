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

class Settings::CurrenciesController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@currency

  def index
    respond_to do |format|
      format.json do
        render :json => @currencies
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @currency.save
        format.json do
          render :json => @currency
        end
      else
        format.json { render :json => @currency.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @currency }
    end
  end

  def update
    respond_to do |format|
      if @currency.update_attributes(params[:currency])
        format.json do
          render :json => @currency
        end
      else
        format.json { render :json => @currency.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @currency.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @currency.errors, :status => :unprocessable_entity }
      end
    end
  end

  def search
    if params[:term].blank?
      results = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      results = @currencies.where("currencies.iso_code ~* ? OR
        currencies.name ~* ? OR
        currencies.iso_numeric ~* ?",
        *([param] * 3)).limit(10)
    end

    respond_to do |format|
      format.json { render :json => results.map{ |p| { :label => p.iso_code, :desc => p.name, :id => p.id }}}
    end
  end

end
