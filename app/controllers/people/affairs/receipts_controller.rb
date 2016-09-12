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

class People::Affairs::ReceiptsController < ApplicationController

  layout false

  load_resource :person
  load_resource :affair
  load_and_authorize_resource through: :affair

  def index
    @affair = Affair.find(params[:affair_id])
    @receipts = @affair.receipts

    if params[:template_id]
      @affair.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @receipts }

      format.csv do
        fields = []
        fields << 'value_date'
        fields << 'means_of_payment'
        fields << 'value'
        fields << 'created_at.try(:to_date)'
        fields << 'owner.first_name'
        fields << 'owner.last_name'
        fields << 'owner.full_address'
        fields << 'owner.try(:location).try(:postal_code_prefix)'
        fields << 'owner.try(:location).try(:country).try(:name)'
        fields << 'owner.main_communication_language.try(:name)'
        fields << 'owner.email'
        render inline: csv_ify(@receipts, fields)
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
                    filename: "affair_receipts_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator = AttachmentGenerator.new(@affair)
          generator.odt { |o,odt| @odt = odt.read }
          send_data @odt,
                    filename: "affair_receipts_#{params[:affair_id]}.odt",
                    type: 'application/vnd.oasis.opendocument.text'
        end
      end
    end

  end

  def show
    edit
  end

  def create
    @receipt.value = params[:value]
    respond_to do |format|
      if @receipt.save
        format.json { render json: @receipt }
      else
        format.json { render json: @receipt.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @receipt }
    end
  end

  def update
    @receipt.value = params[:value]
    respond_to do |format|
      if @receipt.update_attributes(params[:receipt])
        format.json { render json: @receipt }
      else
        format.json { render json: @receipt.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @receipt.destroy
        format.json { render json: {} }
      else
        format.json { render json: @receipt.errors, status: :unprocessable_entity }
      end
    end
  end

end
