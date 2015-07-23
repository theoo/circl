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

class Admin::InvoicesController < ApplicationController

  include ControllerExtensions::Invoices

  layout false

  load_and_authorize_resource except: :index

  def index
    authorize! :index, Invoice

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

        @invoices = Invoice.order(:created_at)

        # fetch invoices corresponding to selected statuses and interval
        if params[:statuses]
          mask = params[:statuses].map(&:to_i).sum
          @invoices = @invoices.where("(invoices.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
        end

        if params[:title_filter]
          begin # Postgresql may trow an error if regexp is not correct
            @invoices = @invoices.where("invoices.title ~ ?", params[:title_filter])
          end
        end

        if from and to
          @invoices = @invoices.where("created_at BETWEEN ? AND ?", from, to)
        end

        # raise ArgumentError, @invoices.sql.inspect
        @invoices.uniq!

        if ['pdf', 'odt'].index params[:format]
          # Ensure at least a template is given
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find params[:generic_template_id]
          fake_object.invoices = @invoices

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json { render json: InvoicesDatatable.new(view_context) }

        format.csv do
          fields = []
          fields << 'title'
          fields << 'created_at.try(:to_date)'
          fields << 'value'
          fields << 'value_with_taxes'
          fields << 'vat'
          fields << 'receipts_value'
          fields << 'get_statuses.try(:join, ", ")'
          fields << 'owner.organization_name'
          fields << 'owner.first_name'
          fields << 'owner.last_name'
          fields << 'owner.full_address'
          fields << 'owner.try(:location).try(:postal_code_prefix)'
          fields << 'owner.try(:location).try(:country).try(:name)'
          fields << 'owner.try(:main_communication_language).try(:name)'
          fields << 'owner.email'
          render inline: csv_ify(@invoices, fields)
        end

        format.pdf do
          send_data generator.pdf,
            filename: "invoices.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            filename: "invoices.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render json: errors, status: :unprocessable_entity
        end
      end
    end
  end

  def export
    from = Date.parse(params[:from]) if validate_date_format(params[:from])
    to   = Date.parse(params[:to]) if validate_date_format(params[:to])

    if ! params[:subscription_id].blank?
      receipt_arel = Subscription.find(params[:subscription_id]).invoices
    else
      receipt_arel = Invoice
    end

    respond_to do |format|
      format.html do
        if from && to
          # NOTE to_time allow rails to search UTC date which may be different between summer and winter
          invoices = Invoice.where('created_at >= ? AND created_at <= ?', from.to_time, to.to_time).order(:created_at)
          exporter = Exporter::Factory.new( :invoices,
                                            params[:type].to_sym,
                                            { account: params["account"], counterpart_account: params['counterpart_account'] })
          send_data( exporter.export(invoices),
                     type: 'application/octet-stream',
                     filename: "invoices_#{from}_#{to}_#{params[:type]}.csv",
                     disposition: 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to admin_path
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to person_path(@invoice.affair.owner, anchor: "affairs/#{@invoice.affair.id}")}
      format.json { render json: @invoice }
    end
  end

  # search is in extention

  def available_statuses
    a = Invoice.available_statuses
    a.delete(nil)
    statuses = a.each_with_object({}) do |s, h|
      h[Invoice.statuses_value_for(s).to_s] = s
    end

    respond_to do |format|
      format.json { render json: statuses }
    end
  end

end
