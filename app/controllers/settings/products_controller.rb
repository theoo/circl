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

class Settings::ProductsController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@product

  def index

    @product.actives if params[:actives]

    respond_to do |format|
      format.json do
        render :json => @products
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @product.save
        format.json do
          render :json => @product
        end
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @product }
    end
  end

  def update
    respond_to do |format|
      if @product.update_attributes(params[:product])
        format.json do
          render :json => @product
        end
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @product.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

end
