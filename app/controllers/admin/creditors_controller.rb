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

class Admin::CreditorsController < ApplicationController

  respond_to :json

  layout false

  skip_before_action :verify_authenticity_token

  load_and_authorize_resource except: [:index, :check_item, :uncheck_item, :group_destroy, :group_update]

  before_filter :set_money, only: [:create, :update]

  def index
    authorize! :index, Creditor

    errors = {}

    if ['pdf', 'odt'].index params[:format]
      unless params[:generic_template_id]
        errors[:generic_template_id] = I18n.t("activerecord.errors.messages.blank")
      end
    end

    respond_to do |format|

      if errors.empty?

        format.json { render json: CreditorsDatatable.new(view_context) }

        @creditors = Creditor.where(id: params[:items])

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
          render inline: csv_ify(@creditors, fields)
        end

        if ['pdf', 'odt'].index params[:format]
          # Ensure at least a template is given
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find params[:generic_template_id]
          fake_object.creditors = @creditors

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        format.pdf do
          send_data generator.pdf,
            filename: "creditors.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            filename: "creditors.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end
      else
        format.all do
          # TODO improve display
          flash[:error] = errors.inspect
          redirect_to admin_path(anchor: 'creditors')
        end
      end
    end
  end


  def check_items
    authorize! :index, Creditor

    session[:admin_creditors] ||= []
    session[:admin_creditors].push *select_items
    session[:admin_creditors].uniq!

    respond_to do |format|
      format.json { render json: session[:admin_creditors] }
    end
  end

  def uncheck_items
    authorize! :index, Creditor

    session[:admin_creditors] ||= []
    session[:admin_creditors].delete_if {|e| select_items.index(e)}

    # Sort of reset in case of complications
    session[:admin_creditors] = [] if params[:group] == 'all'

    respond_to do |format|
      format.json { render json: session[:admin_creditors] }
    end
  end

  def select_items

    if params[:id]
      arel = Creditor.where(id: params[:id])
    elsif params[:group]
      valid_statuses = Creditor.statuses.keys
      valid_statuses << :all
      return [] unless valid_statuses.index(params[:group].to_sym)
      arel = Creditor.send(params[:group])
    end

    return [] if arel.nil?

    unless params[:from].blank?
      from = Date.parse params[:from] if validate_date_format(params[:from])
      arel = arel.where('? < creditors.invoice_received_on', from)
    end

    unless params[:to].blank?
      to = Date.parse params[:to] if validate_date_format(params[:to])
      arel = arel.where('creditors.invoice_received_on < ?', to)
    end

    arel.pluck(:id)

  end

  # def export
  #   authorize! :index, Creditor

  #   errors = {}
  #   # pseudo validation
  #   unless params[:from].blank?
  #     if validate_date_format(params[:from])
  #       from = Date.parse params[:from]
  #     else
  #       errors[:from] = I18n.t("creditor.errors.wrong_date")
  #     end
  #   end

  #   unless params[:to].blank?
  #     if validate_date_format(params[:to])
  #       to = Date.parse params[:to]
  #     else
  #       errors[:to] = I18n.t("creditor.errors.wrong_date")
  #     end
  #   end

  #   if from and to and from > to
  #     errors[:from] = I18n.t("salary.errors.from_date_should_be_before_to_date")

  #     unless params[:date_field].blank?
  #       if Creditor.date_fields.index params[:date_field]
  #         date_field = params[:date_field]
  #       else
  #         errors[:statuses] = I18n.t("creditors.errors.date_field_unkown")
  #       end
  #     end
  #   end

  #   unless params[:status].blank?
  #     unless Creditor.statuses.index params[:status]
  #       status = params[:status]
  #     else
  #       errors[:statuses] = I18n.t("creditors.errors.invalid_status")
  #     end
  #   end

  #   if ['pdf', 'odt'].index params[:format]
  #     unless params[:generic_template_id]
  #       errors[:generic_template_id] = I18n.t("activerecord.errors.messages.blank")
  #     end
  #   end

  #   respond_to do |format|

  #     if errors.empty?
  #       ######### PREPARE ############

  #       @creditors = Creditor.order(:created_at)
  #       @creditors = @creditors.send(status) if status

  #       if from and to
  #         @creditors = @creditors.where("#{date_field} BETWEEN ? AND ?", from, to)
  #       end

  #       if ['pdf', 'odt'].index params[:format]
  #         # Ensure at least a template is given
  #         # build generator using selected generic template
  #         fake_object = OpenStruct.new
  #         fake_object.template = GenericTemplate.find params[:generic_template_id]
  #         fake_object.creditors = @creditors

  #         generator = AttachmentGenerator.new(fake_object, nil)
  #       end

  #       ######### RENDER ############

  #       format.json { render json: CreditorsDatatable.new(view_context) }

  #       format.csv do
  #         fields = []
  #         fields << 'id'
  #         fields << 'owner_id'
  #         fields << 'owner.try(:name)'
  #         fields << 'buyer_id'
  #         fields << 'buyer.try(:name)'
  #         fields << 'receiver_id'
  #         fields << 'receiver.try(:name)'
  #         fields << 'title'
  #         fields << 'description'
  #         fields << 'value'
  #         fields << 'overpaid_value'
  #         fields << 'get_statuses.join(", ")'
  #         fields << 'created_at'
  #         fields << 'updated_at'
  #         render inline: csv_ify(@creditors, fields)
  #       end

  #       format.pdf do
  #         send_data generator.pdf,
  #           filename: "creditors.pdf",
  #           type: 'application/pdf'
  #       end

  #       format.odt do
  #         send_data generator.odt,
  #           filename: "creditors.odt",
  #           type: 'application/vnd.oasis.opendocument.text'
  #       end

  #     else
  #       format.json do
  #         render json: errors, status: :unprocessable_entity
  #       end
  #     end
  #   end
  # end

  def show
    respond_with(@creditor)
  end

  def create
    if @creditor.save
      render json: @creditor
    else
      render json: @creditor.errors, status: :unprocessable_entity
    end
  end

  def edit
    respond_with(@creditor)
  end

  def group_update
    authorize! :update, Creditor

    errors = nil
    success = false

    Creditor.transaction do
      @creditors = Creditor.find(params[:ids])

      params = creditor_params

      @creditors.each do |c|
        c.update_attributes params

        if c.errors.size > 0
          errors = c.errors
          raise ActiveRecord::Rollback
        end
      end

      success = true
    end

    respond_to do |format|
      if success
        format.json { render json: @creditors }
      else
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @creditor.update_attributes(creditor_params)
      render json: @creditor
    else
      render json: @creditor.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @creditor.destroy
    respond_with(@creditor)
    # format.json { render json: @creditor.errors, status: :unprocessable_entity }
  end

  def group_destroy
    authorize! :destroy, Creditor

    errors = nil
    success = false

    Creditor.transaction do
      @creditors = Creditor.where(id: params[:ids])
      success = @creditors.destroy_all
    end

    respond_to do |format|
      if success
        format.json { render json: @creditors }
      else
        format.json { render json: I18n.t("common.errors.failed_to_destroy"), status: :unprocessable_entity }
      end
    end
  end

  def export
    from = Date.parse(params[:from]) if validate_date_format(params[:from])
    to   = Date.parse(params[:to]) if validate_date_format(params[:to])

    creditor_arel = Creditor

    if Creditor.statuses.index params[:status]
      creditor_arel = creditor_arel.send(params[:status])
    end

    if Creditor.statuses.index params[:dates_field]
      # NOTE to_time allow rails to search UTC date which may be different between summer and winter
      creditor_arel = creditor_arel
        .where('? >= ? AND ? <= ?',
          params[:dates_field],
          from.to_time,
          params[:dates_field],
          to.to_time)
        .order(:created_at)
    end

    respond_to do |format|
      format.html do
        if from && to
          exporter = Exporter::Factory.new( :creditors,
                                            params[:type].to_sym,
                                            { account: params["account"] } )
          send_data( exporter.export(creditor_arel.all),
                     type: 'application/octet-stream',
                     filename: "creditors_#{from}_#{to}_#{params[:type]}.csv",
                     disposition: 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to admin_path(anchor: "creditors")
        end
      end
    end
  end

  private

    def set_money
      @creditor.value = Money.new(params[:value].to_f * 100, params[:value_currency]) if params[:value]
      @creditor.vat = Money.new(params[:vat].to_f * 100, params[:vat_currency]) if params[:vat]
    end

    def creditor_params
      params.permit(
        :creditor_id,
        :affair_id,
        :title,
        :description,
        :value,
        :value_in_cents,
        :value_currency,
        :custom_value_with_taxes,
        :vat,
        :vat_in_cents,
        :vat_currency,
        :vat_percentage,
        :invoice_received_on,
        :invoice_ends_on,
        :invoice_in_books_on,
        :discount_percentage,
        :discount_ends_on,
        :paid_on,
        :payment_in_books_on,
        :updated_at)
    end

end
