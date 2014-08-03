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
  load_and_authorize_resource through: :affair

  monitor_changes :@extra

  def index

    @affair = Affair.find(params[:affair_id])
    @extras = @affair.extras

    if params[:template_id]
      @affair.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @extras }

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
        render inline: csv_ify(@extras, fields)
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
                    filename: "affair_extras_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator = AttachmentGenerator.new(@affair)
          generator.odt { |o,odt| @odt = odt.read }
          send_data @odt,
                    filename: "affair_extras_#{params[:affair_id]}.odt",
                    type: 'application/vnd.oasis.opendocument.text'
        end
      end
    end
  end

  def show
    edit
  end

  def create
    @extra.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    @extra.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @extra.save
        format.json { render json: @extra }
      else
        format.json { render json: @extra.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @extra }
    end
  end

  def update
    @extra.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    @extra.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @extra.update_attributes(params[:extra])
        format.json { render json: @extra }
      else
        format.json { render json: @extra.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @extra.destroy
        format.json { render json: {} }
      else
        format.json { render json: @extra.errors, status: :unprocessable_entity }
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render json: { count: @affair.extras.count } }
    end
  end

  def change_order
    authorize! :update, @person => Extra
    @extras = Extra.find(params[:id])
    success = false

    Extra.transaction do
      siblings = @affair.extras.order(:position).map(&:id)
      id = siblings.delete_at params[:fromPosition].to_i - 1
      siblings.insert(params[:toPosition].to_i - 1, id)
      siblings.delete(nil) # If there is holes in list they will be replace by nil
      siblings.each_with_index do |s, i|
        u = Extra.find(s)
        u.position = i + 1
        u.save!
      end

      success = true
    end

    respond_to do |format|
      if success
        format.json { render json: @affair.extras.all }
      else
        format.json { render json: @extras.errors, status: :unprocessable_entity }
      end
    end
  end

end
