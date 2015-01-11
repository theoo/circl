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

class Admin::AffairsController < ApplicationController

  include ControllerExtentions::Affairs

  layout false

  load_and_authorize_resource except: :index

  def index
    authorize! :index, Affair

    errors = {}
    # pseudo validation
    unless params[:from].blank?
      if validate_date_format(params[:from])
        from = Date.parse params[:from]
      else
        errors[:from] = I18n.t("affair.errors.wrong_date")
      end
    end

    unless params[:to].blank?
      if validate_date_format(params[:to])
        to = Date.parse params[:to]
      else
        errors[:to] = I18n.t("affair.errors.wrong_date")
      end
    end

    if from and to and from > to
      errors[:from] = I18n.t("salary.errors.from_date_should_be_before_to_date")
    end

    if ['pdf', 'odt'].index params[:format]
      unless params[:generic_template_id]
        errors[:generic_template_id] = I18n.t("activerecord.errors.messages.blank")
      end
    end

    respond_to do |format|

      if errors.empty?
        ######### PREPARE ############

        @affairs = Affair.order(:created_at)

        # fetch affairs corresponding to selected statuses and interval
        if params[:statuses]
          mask = params[:statuses].map(&:to_i).sum
          @affairs = @affairs.where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
        end

        if params[:title_filter]
          begin # Postgresql may trow an error if regexp is not correct
            @affairs = @affairs.where("affairs.title ~ ?", params[:title_filter])
          end
        end

        if from and to
          @affairs = @affairs.where("created_at BETWEEN ? AND ?", from, to)
        end

        # raise ArgumentError, @affairs.sql.inspect
        @affairs.uniq!

        if ['pdf', 'odt'].index params[:format]
          # Ensure at least a template is given
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find params[:generic_template_id]
          fake_object.affairs = @affairs

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json { render json: AffairsDatatable.new(view_context) }

        format.csv do
          fields = []
          fields << 'id'
          fields << 'owner_id'
          fields << 'owner.try(:name)'
          fields << 'buyer_id'
          fields << 'buyer.try(:name)'
          fields << 'receiver_id'
          fields << 'receiver.try(:name)'
          fields << 'title'
          fields << 'description'
          fields << 'value'
          fields << 'overpaid_value'
          fields << 'get_statuses.join(", ")'
          fields << 'created_at'
          fields << 'updated_at'
          render inline: csv_ify(@affairs, fields)
        end

        format.pdf do
          send_data generator.pdf,
            filename: "affairs.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            filename: "affairs.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render json: errors, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to person_path(@affair.owner, anchor: "affairs/#{@affair.id}")}
      format.json { render json: @affair }
    end
  end

  # Search is in AffairsExtention

  def available_statuses
    a = Affair.available_statuses
    a.delete(nil)
    statuses = a.each_with_object({}) do |s, h|
      h[Affair.statuses_value_for(s).to_s] = s
    end

    respond_to do |format|
      format.json { render json: statuses }
    end
  end

end
