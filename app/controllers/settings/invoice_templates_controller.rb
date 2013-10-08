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
      format.json { render :json => @invoice_templates }
    end
  end

  def show
    respond_to do |format|
      format.json { render :json => @invoice_template }
      format.html do
        render :inline => @invoice_template.html, :layout => 'preview.html.haml'
      end
      format.jpg do
        unless @invoice_template.snapshot.path and File.exists? @invoice_template.snapshot.path
          BackgroundTasks::GenerateInvoiceTemplateJpg.process!(:invoice_template_id => @invoice_template.id)
          @invoice_template.reload
        end
        redirect_to @invoice_template.snapshot.url
      end
    end
  end

  def create
    respond_to do |format|
      if @invoice_template.save
        BackgroundTasks::GenerateInvoiceTemplateJpg.process!(:invoice_template_id => @invoice_template.id)
        @invoice_template.reload
        format.json { render :json => @invoice_template }
      else
        format.json { render :json => @invoice_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @invoice_template }
      format.html { render :layout => 'template_editor' }
    end
  end

  def update
    respond_to do |format|
      if @invoice_template.update_attributes(params[:invoice_template])
        BackgroundTasks::GenerateInvoiceTemplateJpg.process!(:invoice_template_id => @invoice_template.id)
        @invoice_template.reload
        format.json { render :json => @invoice_template }
      else
        format.json { render :json => @invoice_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @invoice_template.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @invoice_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  def placeholders
    authorize! :manage, InvoiceTemplate

    it = InvoiceTemplate.new(:language => @current_person.main_communication_language)
    placeholders = it.placeholders

    respond_to do |format|
      format.json { render :json => placeholders }
    end
  end

end
