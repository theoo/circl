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

class People::Affairs::InvoicesController < ApplicationController

  include ControllerExtensions::Invoices

  layout false

  load_resource :person
  load_resource :affair
  load_and_authorize_resource through: :affair, except: :bvr_preview

  # NOTE Only for testing purpose
  skip_filter :authenticate_person!

  monitor_changes :@invoice

  def index
    @affair = Affair.find(params[:affair_id])
    @invoices = @affair.invoices

    if params[:template_id]
      @affair.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @invoices }

      format.csv do
        fields = []
        fields << 'title'
        fields << 'created_at.try(:to_date)'
        fields << 'value'
        fields << 'value_with_taxes'
        fields << 'vat'
        fields << 'owner.first_name'
        fields << 'owner.last_name'
        fields << 'owner.full_address'
        fields << 'owner.try(:location).try(:postal_code_prefix)'
        fields << 'owner.try(:location).try(:country).try(:name)'
        fields << 'owner.try(:main_communication_language).try(:name)'
        fields << 'owner.email'
        render inline: csv_ify(@invoices, fields)
      end

      if params[:template_id]
        generator = AttachmentGenerator.new(@affair)

        format.html do
          render inline: generator.html, layout: 'preview'
        end

        format.pdf do
          @pdf = ""
          generator.pdf { |o,pdf| @pdf = pdf.read }
          send_data @pdf,
                    filename: "affair_invoices_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator.odt { |o,odt| @odt = odt.read }
          send_data @odt,
                    filename: "affair_invoices_#{params[:affair_id]}.odt",
                    type: 'application/vnd.oasis.opendocument.text'
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @invoice }

      # Render HTML but don't build PDF.
      format.html do
        generator = AttachmentGenerator.new(@invoice)
        render inline: generator.html, layout: 'preview'
      end

      # Call Background task to build pdf through invoice model.
      format.pdf do
        unless @invoice.pdf_up_to_date? and File.exist?(@invoice.pdf.path)
          @invoice.update_pdf!
          @invoice.reload
        end
        send_data File.read(@invoice.pdf.path), filename: "invoice_#{params[:id]}.pdf", type: 'application/pdf'
      end
    end
  end

  def create
    @invoice.custom_value_with_taxes = params[:custom_value_with_taxes]
    @invoice.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    @invoice.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @invoice.save
        format.json { render json: @invoice }
      else
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def bvr_preview
    @invoice = Invoice.find(params[:id])
    l = params["frame"].nil? ? 'pdf' : 'preview'
    respond_to do |format|
      format.html { render :bvr, layout: l }
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @invoice }
    end
  end

  def update
    @invoice.custom_value_with_taxes = params[:custom_value_with_taxes]
    @invoice.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    @invoice.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @invoice.update_attributes(params[:invoice])
        format.json { render json: @invoice }
      else
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @invoice.destroy
        format.json { render json: {} }
      else
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # search is in extention

  ##
  # PDF generation
  #

  # Required by generate_invoice_pdf
  def build_from_template(i, html = '')

    @invoice = i
    html = render_to_string("bvr") if @invoice.invoice_template.with_bvr
    html

  end

  private

end
