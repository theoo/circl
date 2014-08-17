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
    @person = Person.find params[:person_id]
    @affair = Affair.find params[:affair_id]
  end

  def index
    authorize! :read, @person => AffairsProductsProgram

    @products = @affair.product_items

    if params[:template_id]
      @affair.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @products }

      format.csv do
        fields = []
        fields << 'position'
        fields << 'parent.try(:position)'
        fields << 'parent.try(:product).try(:key)'
        fields << 'quantity'
        fields << 'product.key'
        fields << 'product.title'
        fields << 'program.description'
        fields << 'product.key'
        fields << 'program.key'
        fields << 'program.title'
        fields << 'program.description'
        fields << 'value'
        render inline: csv_ify(@products, fields)
      end

      if params[:template_id]
        format.html do
          generator = AttachmentGenerator.new(@affair)
          render inline: generator.html, layout: 'preview'
        end

        format.pdf do
          @pdf = ""
          generator = AttachmentGenerator.new(@affair)
          generator.pdf { |o,pdf| @pdf = pdf.read }
          send_data @pdf,
                    filename: "affair_products_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator = AttachmentGenerator.new(@affair)
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

    @product = @affair.product_items.new
    update_instance(params)

    respond_to do |format|
      if @product.save
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
    update_instance(params)

    respond_to do |format|
      if @product.save
        format.json { render json: @product }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
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

  def search
    authorize! :read, @person => AffairsProductsProgram

    @affair_product_programAffairsProductsProgram

    hash = {}
    if ! params[:term].blank?
      result = []
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = Product
        .joins(:product_items)
        .where("affairs_products_programs.affair_id = ?", @affair.id)
        .where("products.key ~* ? OR products.title ~* ?", param, param)
      if result
        hash = result.map{ |t|
          {
            id: @affair.product_items.where(product_id: t.id).first.id,
            label: t.key,
            title: t.title,
            desc: t.description.exerpt
          }
        }
      end
    end

    respond_to do |format|
      format.json { render json: hash }
    end
  end

  def change_order
    authorize! :update, @person => AffairsProductsProgram
    @product = AffairsProductsProgram.find(params[:id])
    success = false

    AffairsProductsProgram.transaction do
      siblings = @affair.product_items.all.to_a
      p = siblings.delete_at params[:fromPosition].to_i - 1
      siblings.insert(params[:toPosition].to_i - 1, p)
      siblings.delete(nil) # If there is holes in list they will be replace by nil
      siblings.each_with_index do |s, i|
        u = AffairsProductsProgram.find(s.id)
        u.update_attributes(position: i + 1)
      end

      success = true
    end

    respond_to do |format|
      if success
        format.json { render json: @affair.product_items.all }
      else
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def update_instance(prod)
    # remove relations if not sent
    prod[:parent_id] = nil unless prod[:parent_id]
    prod[:program_id] = nil unless prod[:program_id]
    prod[:product_id] = nil unless prod[:product_id]

    @product.assign_attributes(
      parent_id: prod[:parent_id],
      program_id: prod[:program_id],
      product_id: prod[:product_id],
      position: prod[:position],
      bid_percentage: prod[:bid_percentage],
      quantity: prod[:quantity])
  end

end
