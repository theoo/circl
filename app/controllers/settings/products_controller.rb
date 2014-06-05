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

  load_and_authorize_resource except: :index

  monitor_changes :@product

  def index
    authorize! :index, Product
    # TODO @product.actives if params[:actives]

    respond_to do |format|
      format.json do
        render json: ProductsDatatable.new(view_context)
      end
    end
  end

  def show
    edit
  end

  def create
    succeed = false

    Product.transaction do

      # raise the error and rollback transaction if validation fails
      raise ActiveRecord::Rollback unless @product.save

      # append variants
      params[:variants].each do |v|
        pv = @product.variants.new(v)

        pv.buying_price = Money.new(v[:buying_price].to_f * 100, v[:buying_price_currency])
        pv.selling_price = Money.new(v[:selling_price].to_f * 100, v[:selling_price_currency])
        pv.art = Money.new(v[:art].to_f * 100, v[:art_currency])

        unless pv.save
          pv.errors.messages.each do |k,v|
            @product.errors.add(("variants[][" + k.to_s + "]").to_sym, v.join(", "))
          end
          raise ActiveRecord::Rollback
        end
      end

      succeed = true
    end

    respond_to do |format|
      if succeed
        format.json do
          render json: @product
        end
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @product }
    end
  end

  def update
    succeed = false

    Product.transaction do
      # Force removal of relation if not sent
      params[:product][:provider_id] = nil unless params[:product][:provider_id]
      params[:product][:after_sale_id] = nil unless params[:product][:after_sale_id]

      # Only keep variants that are returned
      surplus_variants = @product.variants.map(&:id) - params[:variants].map{|v| v[:id].to_i}
      ProductVariant.destroy surplus_variants

      # append or update variants
      params[:variants].each do |v|
        if @product.variants.exists?(v[:id])
          pv = @product.variants.find(v[:id])
          pv.assign_attributes(v)
        else
          pv = @product.variants.new(v)
        end

        pv.buying_price = Money.new(v[:buying_price].to_f * 100, v[:buying_price_currency])
        pv.selling_price = Money.new(v[:selling_price].to_f * 100, v[:selling_price_currency])
        pv.art = Money.new(v[:art].to_f * 100, v[:art_currency])

        unless pv.save
          pv.errors.messages.each do |k,v|
            @product.errors.add(("variants[][" + k.to_s + "]").to_sym, v.join(", "))
          end
          raise ActiveRecord::Rollback
        end
      end

      # raise the error and rollback transaction if validation fails
      raise ActiveRecord::Rollback unless @product.update_attributes(params[:product])

      succeed = true
    end

    respond_to do |format|
      if succeed
        format.json do
          render json: @product
        end
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @product.destroy
        format.json { render json: {} }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @products
        .where("products.key ~* ? OR products.title ~* ? OR products.description ~* ?", *([param]*3))
        .limit(10)
    end

    h = result.map do |p|
      if p.available_programs.count == 1
        { id: p.id,
          label: p.key,
          title: p.title,
          desc: p.description,
          program_key: p.available_programs.first.key,
          program_id: p.available_programs.first.id }
      else
        { id: p.id,
          label: p.key,
          title: p.title,
          desc: p.description }
      end
    end

    respond_to do |format|
      format.json do
        render json: h
      end
    end
  end

  def category_search
    if params[:term].blank?
      results = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      results = @products.where("products.category ~* ?", params[:term])
        .select("DISTINCT(products.category)")
    end

    respond_to do |format|
      format.json { render json: results.map{ |p| { label: p.category }}}
    end
  end

  def programs
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @product
        .available_programs
        .where("product_programs.key ~* ? OR product_programs.title ~* ?", param, param)
        .limit(10)
    end

    respond_to do |format|
      format.json do
        render json: result.map{ |t| { id: t.id,
          label: t.key,
          title: t.title,
          desc: t.description }}
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: Product.count} }
    end
  end

end
