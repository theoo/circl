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

  before_action :set_money, only: [:create, :update]

  def index
    authorize! :index, Creditor

    errors = {}

    if ['pdf', 'odt'].index params[:format]
      unless params[:template_id]
        errors[:template_id] = I18n.t("activerecord.errors.messages.blank")
      end
    end

    respond_to do |format|

      if errors.empty?

        @creditors = Creditor.joins(:creditor)
        @creditors = @creditors.where(id: session[:admin_creditors])

        if params[:sSearch] and params[:sSearch].match("SELECTED")
          subset = @creditors
          params[:sSearch] = params[:sSearch].gsub("SELECTED", "").strip
        end

        format.json { render json: CreditorsDatatable.new(view_context, subset) }

        # It makes no sense to export an empty array.
        @creditors = @creditors.all if @creditors.size == 0

        table_fields = [ :created_at,
          :title,
          "people.organization_name",
          :value_in_cents,
          :invoice_received_on,
          :discount_ends_on,
          :invoice_ends_on,
          :invoice_in_books_on,
          :paid_on,
          :payment_in_books_on ]

        if params[:order_by]
          ob = params[:order_by].split(",")
          @creditors = @creditors.reorder("#{table_fields[ob[0].to_i]} #{ob[1]}")
        end

        format.csv do

          csv_fields = [ :id,
            :creditor_id,
            "creditor.try(:name)",
            :affair_id,
            "affair.try(:title)",
            :title,
            :description,
            :value_in_cents,
            :value_currency,
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
            :account,
            :transitional_account,
            :created_at,
            :updated_at ]

          render inline: csv_ify(@creditors, csv_fields)
        end

        format.pdf do
          send_data build_generator.pdf,
            filename: "creditors.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data build_generator.odt,
            filename: "creditors.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end

        format.txt do

          # TODO catch the 'type' (banana) from user's or directory configuration
          exporter = Exporter::Factory.new(:creditors, :banana)
          send_data( exporter.export(@creditors),
                     type: 'application/octet-stream',
                     filename: "creditors.txt",
                     disposition: 'attachment' )
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

  def preview_import
    authorize! :manage, Creditor

    unless params[:file]
      flash[:alert] = I18n.t('common.errors.no_file_submitted')
      redirect_to settings_path(anchor: 'database')
      return
    end

    session[:admin_creditors_file_data] = params[:file].read
    @creditors, @columns = Creditor.parse_csv(session[:admin_creditors_file_data])

    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  def import

    # TODO Move this to background task
    authorize! :manage, Creditor
    file = session[:admin_creditors_file_data]

    @creditors, @columns = Creditor.parse_csv(file, params[:lines], params[:skip_columns], true)

    success = false
    Creditor.transaction do
      @creditors.each do |p|
        raise ActiveRecord::Rollback unless p.save
      end
      success = true
    end

    respond_to do |format|
      if success
        flash[:notice] = I18n.t('creditor.notices.creditor_imported', email: current_person.email)
        format.html { redirect_to settings_path(anchor: 'database')  }
      else
        flash[:error] = I18n.t('creditor.errors.creditor_failed_to_imported')
        format.html { redirect_to settings_path(anchor: 'database') }
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
        :updated_at,
        :account,
        :discount_account,
        :vat_account,
        :vat_discount_account,
        :transitional_account)
    end

    def build_generator
      fake_reference = OpenStruct.new(template: GenericTemplate.find(params[:template_id]))
      AttachmentGenerator.new(@creditors, fake_reference)
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

      if Creditor.date_fields.keys.index(params[:date_field].try(:to_sym))
        date_field = params[:date_field]
      else
        date_field = "invoice_ends_on"
      end

      unless params[:from].blank?
        from = Date.parse params[:from] if validate_date_format(params[:from])
        arel = arel.where("? <= creditors.#{date_field}", from)
      end

      unless params[:to].blank?
        to = Date.parse params[:to] if validate_date_format(params[:to])
        arel = arel.where("creditors.#{date_field} <= ?", to)
      end

      arel.pluck(:id)

    end

end
