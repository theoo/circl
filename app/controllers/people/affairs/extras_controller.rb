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

class People::Affairs::ExtrasController < ApplicationController

  layout false

  load_resource :person
  load_resource :affair
  load_and_authorize_resource :through => :affair

  monitor_changes :@extra

  def index
    respond_to do |format|
      format.json { render :json => @extras }

      format.csv do
        fields = []
        fields << 'id'
        fields << 'position'
        fields << 'quantity'
        fields << 'title'
        fields << 'description'
        fields << 'value'
        fields << 'created_at'
        fields << 'updated_at'
        render :inline => csv_ify(@extras, fields)
      end

      format.pdf do
        # TODO Allow user to edit this pdf listing through a template
        html = render_to_string(:layout => 'pdf.html.haml')

        html.assets_to_full_path!

        file = Tempfile.new(['extras', '.pdf'], :encoding => 'ascii-8bit')
        file.binmode
        file.write(PDFKit.new(html).to_pdf)
        file.flush

        send_data File.read(file), :filename => "affair_#{params[:affair_id]}_extras.pdf", :type => 'application/pdf'

        file.unlink
      end
    end
  end

  def show
    edit
  end

  def create
    @extra.value = params[:value]
    respond_to do |format|
      if @extra.save
        format.json { render :json => @extra }
      else
        format.json { render :json => @extra.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @extra }
    end
  end

  def update
    @extra.value = params[:value]
    respond_to do |format|
      if @extra.update_attributes(params[:extra])
        format.json { render :json => @extra }
      else
        format.json { render :json => @extra.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @extra.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @extra.errors, :status => :unprocessable_entity }
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render :json => { :count => @affair.extras.count } }
    end
  end

end
