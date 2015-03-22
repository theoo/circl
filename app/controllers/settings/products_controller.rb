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

    respond_to do |format|
      format.json do
        render json: ProductsDatatable.new(view_context, params[:actives])
      end
      format.csv do
        render inline: csv_ify(Product.all, [
          :key,
          :title,
          :description,
          :width,
          :height,
          :depth,
          :volume,
          :weight,
          :unit_symbol,
          :price_to_unit_rate,
          'variants[0].try(:buying_price)',
          'variants[1].try(:buying_price)',
          'variants[2].try(:buying_price)',
          'variants[3].try(:buying_price)',
          'variants[4].try(:buying_price)',
          'variants[5].try(:buying_price)',
          'variants[6].try(:buying_price)',
          'variants[7].try(:buying_price)',
          'variants[8].try(:buying_price)',
          'variants[9].try(:buying_price)',
          'variants[10].try(:buying_price)',
          'variants[11].try(:buying_price)',
          'variants[12].try(:buying_price)',
          'variants[13].try(:buying_price)',
          'variants[14].try(:buying_price)',
          'variants[15].try(:buying_price)',
          'variants[0].try(:selling_price)',
          'variants[1].try(:selling_price)',
          'variants[2].try(:selling_price)',
          'variants[3].try(:selling_price)',
          'variants[4].try(:selling_price)',
          'variants[5].try(:selling_price)',
          'variants[6].try(:selling_price)',
          'variants[7].try(:selling_price)',
          'variants[8].try(:selling_price)',
          'variants[9].try(:selling_price)',
          'variants[10].try(:selling_price)',
          'variants[11].try(:selling_price)',
          'variants[12].try(:selling_price)',
          'variants[13].try(:selling_price)',
          'variants[14].try(:selling_price)',
          'variants[15].try(:selling_price)',
          'variants[0].try(:art_value)',
          'variants[1].try(:art_value)',
          'variants[2].try(:art_value)',
          'variants[3].try(:art_value)',
          'variants[4].try(:art_value)',
          'variants[5].try(:art_value)',
          'variants[6].try(:art_value)',
          'variants[7].try(:art_value)',
          'variants[8].try(:art_value)',
          'variants[9].try(:art_value)',
          'variants[10].try(:art_value)',
          'variants[11].try(:art_value)',
          'variants[12].try(:art_value)',
          'variants[13].try(:art_value)',
          'variants[14].try(:art_value)',
          'variants[15].try(:art_value)',
          'variants[0].try(:program_group)',
          'variants[1].try(:program_group)',
          'variants[2].try(:program_group)',
          'variants[3].try(:program_group)',
          'variants[4].try(:program_group)',
          'variants[5].try(:program_group)',
          'variants[6].try(:program_group)',
          'variants[7].try(:program_group)',
          'variants[8].try(:program_group)',
          'variants[9].try(:program_group)',
          'variants[10].try(:program_group)',
          'variants[11].try(:program_group)',
          'variants[12].try(:program_group)',
          'variants[13].try(:program_group)',
          'variants[14].try(:program_group)',
          'variants[15].try(:program_group)',
          'variants.first.try(:selling_price).try(:currency).try(:iso_code)',
          :provider_id,
          :after_sale_id,
          :category,
          :has_accessories,
          :archive,
          :created_at,
          :updated_at] )
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
      if params[:variants]
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
      else
        @product.variants = []
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
        .actives
        .where("products.key ~* ? OR products.title ~* ? OR products.description ~* ?", *([param]*3))
        .limit(10)
    end

    h = result.map do |p|
      if p.available_programs.count == 1
        { id: p.id,
          label: p.key,
          title: p.title,
          desc: p.description.try(:exerpt),
          program_key: p.available_programs.first.try(:key),
          program_id: p.available_programs.first.try(:id) }
      else
        { id: p.id,
          label: p.key,
          title: p.title,
          desc: p.description.try(:exerpt) }
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
          desc: t.description.exerpt }}
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: Product.count} }
    end
  end

  def preview_import
    authorize! :import, Product

    unless params[:file]
      flash[:alert] = I18n.t('product.errors.no_file_submitted')
      redirect_to settings_path
      return
    end

    session[:product_file_data] = params[:file].read
    @products, @columns = Product.parse_csv(session[:product_file_data])

    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  def import
    # TODO Move this to background task
    authorize! :import, Product
    file = session[:product_file_data]

    @products, @columns = Product.parse_csv(file, params[:lines], params[:skip_columns], true)

    success = false
    Product.transaction do

      @products.each do |p|
        raise ActiveRecord::Rollback unless p.save
      end
      success = true
    end

    respond_to do |format|
      if success
        PersonMailer.send_products_import_report(current_person, @products, @columns).deliver
        flash[:notice] = I18n.t('product.notices.product_imported', email: current_person.email)
        format.html { redirect_to settings_path(anchor: 'affairs')  }
      else
        flash[:error] = I18n.t('product.errors.product_failed_to_imported')
        format.html { redirect_to settings_path(anchor: 'affairs') }
      end
    end

    # In rails 3.1, session is a normal Hash
    # In rails 3.2, session is a CGI::Session
    begin
      session.delete(:product_file_data) # Rails 3.1
      session.data.delete(:product_file_data) # Rails 3.2
    rescue
    end
  end

end
