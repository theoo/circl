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

class Settings::ProductProgramsController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@product_program

  def index

    @product_programs.actives if params[:actives]

    respond_to do |format|
      format.json do
        render :json => @product_programs
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @product_program.save
        format.json do
          render :json => @product_program
        end
      else
        format.json { render :json => @product_program.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @product_program }
    end
  end

  def update
    respond_to do |format|
      if @product_program.update_attributes(params[:product_program])
        format.json do
          render :json => @product_program
        end
      else
        format.json { render :json => @product_program.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @product_program.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @product_program.errors, :status => :unprocessable_entity }
      end
    end
  end

  def variant_name_search
    if params[:term].blank?
      result = []
    else
      result = @product_programs.where("product_programs.variant_name #{SQL_REGEX_KEYWORD} ?", params[:term])
        .select("DISTINCT(product_programs.variant_name)")
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:label => t.variant_name}}}
    end
  end

  def variant_names
    result = @product_programs.select("DISTINCT(product_programs.variant_name)")

    respond_to do |format|
      format.json { render :json => result.map{|t| {:label => t.variant_name}}}
    end
  end

end
