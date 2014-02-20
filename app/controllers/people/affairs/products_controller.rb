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
    authorize! :read, @person => AffairsProductsProgram

    @products = @affair.product_items

    respond_to do |format|
      format.json { render :json => @products }

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
        render :inline => csv_ify(@products, fields)
      end

      format.pdf do
        # TODO Allow user to edit this pdf listing through a template
        html = render_to_string(:layout => 'pdf.html.haml')

        html.assets_to_full_path!

        file = Tempfile.new(['products', '.pdf'], :encoding => 'ascii-8bit')
        file.binmode
        file.write(PDFKit.new(html).to_pdf)
        file.flush

        send_data File.read(file), :filename => "affair_#{params[:affair_id]}_products.pdf", :type => 'application/pdf'

        file.unlink
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
        format.json { render :json => @product }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :read, @person => AffairsProductsProgram

    @product = @affair.product_items.find(params[:id])

    respond_to do |format|
      format.json { render :json => @product }
    end
  end

  def update
    authorize! :update, @person => AffairsProductsProgram

    @product = @affair.product_items.find(params[:id])
    update_instance(params)

    respond_to do |format|
      if @product.save
        format.json { render :json => @product }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, @person => AffairsProductsProgram

    @product = @affair.product_items.find(params[:id])

    respond_to do |format|
      if @product.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
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
            :id => @affair.product_items.where(:product_id => t.id).first.id,
            :label => t.key,
            :title => t.title,
            :desc => t.description
          }
        }
      end
    end

    respond_to do |format|
      format.json { render :json => hash }
    end
  end

  def change_order
    authorize! :update, @person => AffairsProductsProgram
    @product = AffairsProductsProgram.find(params[:id])
    success = false

    AffairsProductsProgram.transaction do
      siblings = @affair.product_items.all
      p = siblings.delete_at params[:fromPosition].to_i
      siblings.insert(params[:toPosition].to_i, p)
      siblings.delete(nil) # If there is holes in list they will be replace by nil
      siblings.each_with_index do |s, i|
        u = AffairsProductsProgram.find(s.id)
        u.update_attributes(:position => i)
      end

      success = true
    end

    respond_to do |format|
      if success
        format.json { render :json => @affair.product_items.all }
      else
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
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
      :parent_id  => prod[:parent_id],
      :program_id => prod[:program_id],
      :product_id => prod[:product_id],
      :position   => prod[:position],
      :quantity   => prod[:quantity])
  end

end
