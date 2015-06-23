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

# TODO Rename product in item to prevent confusion

class People::Affairs::ProductsController < ApplicationController

  layout false

  monitor_changes :@product

  before_filter do
    @person = Person.find params[:person_id]
    @affair = Affair.find params[:affair_id]
  end

  def index
    authorize! :read, @person => AffairsProductsProgram

    params[:items] = JSON.parse(params[:items]) if params[:items]

    if params[:items] and not params[:items].blank? and not params[:export_all]
      @products = @affair.product_items.where(id:params[:items])
    else
      @products = @affair.product_items
    end

    if @products.count > 0
      reference = @products.first
    else
      reference = @affair.product_items.first
    end

    if params[:template_id]
      reference.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @products }

      format.csv do
        fields = []
        fields << 'position'
        fields << 'parent.try(:position)'
        fields << 'category.try(:title)'
        fields << 'category.try(:position)'
        fields << 'parent.try(:product).try(:key)'
        fields << 'quantity'
        fields << 'product.key'
        fields << 'product.title'
        fields << 'program.description'
        fields << 'program.key'
        fields << 'program.title'
        fields << 'program.description'
        fields << 'value'
        render inline: csv_ify(@products, fields)
      end

      if params[:template_id]
        format.html do
          generator = AttachmentGenerator.new(@products, reference)
          render inline: generator.html, layout: 'preview'
        end

        format.pdf do
          @pdf = ""
          generator = AttachmentGenerator.new(@products, reference)
          generator.pdf { |o,pdf| @pdf = pdf.read }
          send_data @pdf,
                    filename: "affair_products_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator = AttachmentGenerator.new(@products, reference)
          generator.odt { |o,odt| @odt = odt.read }
          send_data @odt,
                    filename: "affair_products_#{params[:affair_id]}.odt",
                    type: 'application/vnd.oasis.opendocument.text'
        end
      end
    end
  end

  def show
    edit
  end

  def create
    authorize! :create, @person => AffairsProductsProgram

    # If @affair.product_items << OBJ is used, then update_on_prestation_alteration is called
    # which will fail as long as the product item is not saved.
    params[:affair_id] = @affair.id
    @product = AffairsProductsProgram.new(product_params)

    respond_to do |format|
      if @product.save
        # Triggered manually here
        @affair.update_on_prestation_alteration
        format.json { render json: @product }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :read, @person => AffairsProductsProgram

    @product = @affair.product_items.find(params[:id])

    respond_to do |format|
      format.json { render json: @product }
    end
  end

  def update
    authorize! :update, @person => AffairsProductsProgram

    @product = @affair.product_items.find(params[:id])

    respond_to do |format|
      if @product.update_attributes(product_params)
        format.json { render json: @product }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def group_update
    authorize! :update, @person => AffairsProductsProgram

    errors = nil
    success = false

    @affair.product_items.transaction do
      @products = @affair.product_items.find(params[:ids])

      params = product_params

      @products.each do |p|
        p.update_attributes params

        if p.errors.size > 0
          errors = p.errors
          raise ActiveRecord::Rollback
        end
      end

      success = true
    end

    respond_to do |format|
      if success
        format.json { render json: @products }
      else
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, @person => AffairsProductsProgram

    @product = @affair.product_items.find(params[:id])

    respond_to do |format|
      if @product.destroy
        format.json { render json: {} }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def group_destroy
    authorize! :destroy, @person => AffairsProductsProgram

    errors = nil
    success = false

    @affair.product_items.transaction do
      @products = @affair.product_items.where(id: params[:ids])
      success = @products.destroy_all
    end

    respond_to do |format|
      if success
        format.json { render json: @products }
      else
        format.json { render json: I18n.t("common.errors.failed_to_destroy"), status: :unprocessable_entity }
      end
    end
  end

  def search
    authorize! :read, @person => AffairsProductsProgram

    hash = {}
    if ! params[:term].blank?
      result = []
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = Product
        .joins(:product_items)
        .where("affairs_products_programs.affair_id = ?", @affair.id)

      if param.is_i?
        result = result.where("affairs_products_programs.position = ?", param)
      else
        result = result.where("products.key ~* ? OR products.title ~* ?", *([param]*2))
      end

      if result
        hashes = result.map{ |t|
          @affair.product_items.where(product_id: t.id).map do |pi|
            unless pi.parent
              {
                id: pi.try(:id),
                label: t.key,
                title: t.title,
                description: t.description,
                desc: "position: " + pi.try(:position).try(:to_s)
              }
            end
          end
        }
        hashes = hashes.flatten.uniq
        hashes.delete(nil)
      end
    end

    respond_to do |format|
      format.json { render json: hashes }
    end
  end

  def categories
    authorize! :read, @person => AffairsProductsProgram

    hash = {}
    if ! params[:term].blank?
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes

      result = @affair.product_categories.where("title ~ ?", param)

      if result
        hash = result.map{ |t| {label: t.title} }
      end
    end

    respond_to do |format|
      format.json { render json: hash }
    end
  end

  def change_position
    authorize! :update, @person => AffairsProductsProgram
    @product = AffairsProductsProgram.find(params[:id])

    # send table index position
    success = @product.update_table_index_position(params[:toPosition].to_i - 1)
    # success = AffairsProductsProgram.update_position(@product.id, params[:fromPosition].to_i, params[:toPosition].to_i)

    respond_to do |format|
      if success
        format.json { render json: @affair.product_items.all }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def reorder
    authorize! :update, @person => AffairsProductsProgram

    success = @affair.reorder_product_items!


    respond_to do |format|
      if success
        format.json { render json: @affair.product_items.all }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # FIXME: Ensure affair is accessible by person
  def product_params
    params[:value_currency] = ApplicationSetting.value("default_currency") if params[:value_currency].blank?

    category = params[:category]
    if ! category.blank?
      cat = @affair.product_categories.where(title: category).first
      cat ||= @affair.product_categories.create!(title: category)
      params[:category_id] = cat.id
    end
    params.delete(:category)

    p = params.permit(
        :parent_id,
        :program_id,
        :product_id,
        :affair_id,
        :category_id,
        :value,
        :value_currency,
        :position,
        :bid_percentage,
        :quantity,
        :comment,
        :ordered_at,
        :confirmed_at,
        :delivery_at,
        :warranty_begin,
        :warranty_end,
        :category_id,
        :ids
      )

    p
  end

end
