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

class People::Affairs::ProductsController < ApplicationController

  layout false

  monitor_changes :@product

  before_filter do
    @person = Affair.find params[:person_id]
    @affair = Affair.find params[:affair_id]
  end

  def index
    authorize! :read, @person => AffairsProductVariant

    @products = @affair.product_variants

    respond_to do |format|
      format.json { render :json => @products }
      format.csv do
        fields = []
        fields << 'title'
        fields << 'value'
        render :inline => csv_ify(@products, fields)
      end
    end
  end

  def show
    edit
  end

  def create
    authorize! :create, @person => AffairsProductVariant

    # remove relations if not sent
    params[:parent_id] = nil unless params[:parent_id]
    params[:program_id] = nil unless params[:program_id]
    params[:variant_id] = nil unless params[:variant_id]

    @product = @affair.product_variant.new(params)

    respond_to do |format|
      if @product.save
        format.json { render :json => @product }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :read, @person => AffairsProductVariant

    @product = @affair.product_variants.find(params[:id])

    respond_to do |format|
      format.json { render :json => @product }
    end
  end

  def update
    authorize! :update, @person => AffairsProductVariant

    @product = @affair.product_variants.find(params[:id])

    @product.value = params[:value]
    respond_to do |format|
      if @product.update_attributes(params[:product])
        format.json { render :json => @product }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, @person => AffairsProductVariant

    @product = @affair.product_variants.find(params[:id])

    respond_to do |format|
      if @product.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def search
    authorize! :read, @person => AffairsProductVariant

    @products = @affair.product_variants

    if params[:term].blank?
      result = []
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @products.joins(:product).where("products.key #{SQL_REGEX_KEYWORD} ? OR products.title #{SQL_REGEX_KEYWORD} ?", param, param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.title}}}
    end
  end

end
