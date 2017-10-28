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

  include ControllerExtensions::Affairs

  layout false

  load_and_authorize_resource except: :index

  def index
    authorize! :index, Affair

    errors = {}

    if ['pdf', 'odt'].index params[:format]
      unless params[:generic_template_id]
        errors[:generic_template_id] = I18n.t("activerecord.errors.messages.blank")
      end
    end

    respond_to do |format|

      if errors.empty?
        ######### PREPARE ############

        @affairs = Affair.order(:created_at)

        if session[:selected_admin_affairs]
          @affairs = @affairs.where(id: session[:selected_admin_affairs])
        end

        if params[:sSearch] and params[:sSearch].match("SELECTED")
          subset = @affairs
          params[:sSearch] = params[:sSearch].gsub("SELECTED", "").strip
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

        format.json { render json: AffairsDatatable.new(view_context, subset) }

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

  # Search is in AffairsExtension

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

  def check_items
    authorize! :index, Affair

    session[:selected_admin_affairs] ||= []
    session[:selected_admin_affairs].push *select_items
    session[:selected_admin_affairs].uniq!

    respond_to do |format|
      format.json { render json: session[:selected_admin_affairs] }
    end
  end

  def uncheck_items
    authorize! :index, Affair

    session[:selected_admin_affairs] ||= []

    items = select_items
    session[:selected_admin_affairs].delete_if {|e| items.include?(e)}

    respond_to do |format|
      format.json { render json: session[:selected_admin_affairs] }
    end
  end

  def archive_items
    authorize! :index, Affair

    new_attributes = params.select{|k,v|[:archive, :unbillable].include? k.to_sym }

    Affair.where(id: session[:selected_admin_affairs]).each do |a|
      a.update_attributes(new_attributes)
    end

    respond_to do |format|
      format.json { render json: {}, status: :ok }
    end

  end

  private

    def select_items

      if params[:id]
        arel = Affair.where(id: params[:id])
      elsif params[:group]
        valid_statuses = Affair.translated_statuses.keys
        valid_statuses << :all
        return [] unless valid_statuses.index(params[:group].to_sym)
        if params[:group].to_sym == :all
          arel = Affair
        else
          arel = Affair.with_status(params[:group])
        end
      end

      return [] if arel.nil?

      if params[:sSearch] and not params[:sSearch].empty?

        if params[:sSearch].match("SELECTED")
          params[:sSearch] = params[:sSearch].gsub("SELECTED", "").strip
        end

        arel = AffairsDatatable.new(view_context, arel).affairs_arel
      end

      if Affair.translated_date_fields.keys.index(params[:date_field].try(:to_sym))
        date_field = params[:date_field]
      else
        date_field = "created_at"
      end

      unless params[:from].blank?
        from = Date.parse params[:from] if validate_date_format(params[:from])
        arel = arel.where("? <= affairs.#{date_field}", from)
      end

      unless params[:to].blank?
        to = Date.parse params[:to] if validate_date_format(params[:to])
        arel = arel.where("affairs.#{date_field} <= ?", to)
      end

      arel.pluck(:id)

    end

end
