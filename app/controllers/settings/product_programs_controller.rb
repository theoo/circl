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

  def program_group_search
    if params[:term].blank?
      result = []
    else
      result = @product_programs.where("product_programs.program_group ~* ?", params[:term])
        .select("DISTINCT(product_programs.program_group)")
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:label => t.program_group}}}
    end
  end

  def program_groups
    result = @product_programs.select("DISTINCT(product_programs.program_group)")

    respond_to do |format|
      format.json { render :json => result.map{|t| t.program_group}}
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @product_programs.where("product_programs.key ~* ? OR product_programs.title ~* ?", param, param)
    end

    respond_to do |format|
      format.json do
        render :json => result.map{ |t| { :id => t.id,
          :label => t.key,
          :title => t.title,
          :desc => t.description }}
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render :json => {:count => ProductProgram.count} }
    end
  end

end
