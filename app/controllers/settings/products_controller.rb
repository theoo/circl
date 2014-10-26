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
    authorize! :preview_import, Product

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
    raise ArgumentError, params.inspect
    respond_to do |format|
      if success
        format.html { redirect_to settings_path }
      else
        format.html { render preview_import }
      end
    end

    # In rails 3.1, session is a normal Hash
    # In rails 3.2, session is a CGI::Session
    begin
      session.delete(:people_file_data) # Rails 3.1
      session.data.delete(:people_file_data) # Rails 3.2
    rescue
    end

  end

  def import_people
    authorize! :import_people, Directory

    report = {}

    Person.transaction do
      # Create tags first
      if params[:private_tags]
        params[:private_tags].each do |tag|
          PrivateTag.create(name: tag)
        end
      end
      if params[:public_tags]
        params[:public_tags].each do |tag|
          PublicTag.create(name: tag)
        end
      end
      # Create missing jobs
      if params[:jobs]
        params[:jobs].each do |job|
          Job.create(name: job)
        end
      end

      # Temporarly disable geoloc and ES
      Rails.configuration.settings['maps']['enable_geolocalization'] = false
      Rails.configuration.settings['elasticsearch']['enable_indexing'] = false
      # Then re-parse file and import people
      report = Person.parse_people(session[:people_file_data])
      report[:people].each do |p|
        comments = p.comments_edited_by_others.dup
        p.comments_edited_by_others = []
        p.save
        p.comments_edited_by_others = comments
        comments.each{|c| c.save}
      end

      # Ensure ES and geoloc are enable again
      Rails.configuration.settings['elasticsearch']['enable_indexing'] = true
      Rails.configuration.settings['maps']['enable_geolocalization'] = true

      # Reindex the whole database
      BackgroundTasks::RunRakeTask.schedule(name: 'elasticsearch:sync')
    end

    # Ensure ES and geoloc are enable again
    Rails.configuration.settings['elasticsearch']['enable_indexing'] = true
    Rails.configuration.settings['maps']['enable_geolocalization'] = true


    PersonMailer.send_people_import_report(current_person, report[:people]).deliver
    flash[:notice] = I18n.t('directory.notices.people_imported', email: current_person.email)
    Activity.create!(person: current_person, resource_type: 'Admin', resource_id: '0', action: 'info', data: { people: "imported at #{Time.now}" })
    redirect_to directory_path
  end

end
