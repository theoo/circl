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

class Settings::InvoiceTemplatesController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@invoice_template

  def index
    respond_to do |format|
      format.json { render json: @invoice_templates }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @invoice_template }
      format.jpg do
        unless @invoice_template.snapshot.path and File.exists? @invoice_template.snapshot.path
          Templates::InvoiceThumbnails.perform(nil, ids: @invoice_template.id)
          @invoice_template.reload
        end
        redirect_to @invoice_template.snapshot.url
      end
    end
  end

  def create
    respond_to do |format|
      if @invoice_template.save
        Templates::InvoiceThumbnails.perform(nil, ids: @invoice_template.id)
        @invoice_template.reload
        format.json { render json: @invoice_template }
      else
        format.json { render json: @invoice_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @invoice_template }
      format.html { render layout: 'minimal' }
    end
  end

  def update
    respond_to do |format|
      if @invoice_template.update_attributes(params[:invoice_template])
        Templates::InvoiceThumbnails.perform(nil, ids: @invoice_template.id)
        @invoice_template.reload
        format.json { render json: @invoice_template }
        format.html do
          flash[:notice] = I18n.t("common.notices.successfully_updated")
          redirect_to edit_settings_invoice_template_path(@invoice_template)
        end
      else
        format.json { render json: @invoice_template.errors, status: :unprocessable_entity }
        format.html do
          flash[:error] = I18n.t("common.errors.failed_to_update")
          render 'edit', layout: 'minimal'
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if @invoice_template.destroy
        format.json { render json: {} }
      else
        format.json { render json: @invoice_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def upload_odt
    authorize! :manage, InvoiceTemplate

    @invoice_template = InvoiceTemplate.find params[:id]
    @invoice_template.odt = params[:odt]

    respond_to do |format|
      if @invoice_template.save
        Templates::InvoiceThumbnails.perform(nil, ids: @invoice_template.id)
        format.json { render json: @invoice_template }
      else
        format.json { render json: {errors: @invoice_template.errors}, status: :unprocessable_entity }
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: InvoiceTemplate.count} }
    end
  end

end
