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

class Admin::ReceiptsController < ApplicationController

  layout false

  load_and_authorize_resource :receipt, except: :index, parent: false

  def index
    authorize! :index, Receipt
    respond_to do |format|
      format.json { render json: ReceiptsDatatable.new(view_context) }
    end
  end

  def export
    authorize! :export, Receipt

    from = Date.parse(params[:from]) if validate_date_format(params[:from])
    to   = Date.parse(params[:to]) if validate_date_format(params[:to])

    if ! params[:subscription_id].blank?
      receipt_arel = Subscription.find(params[:subscription_id]).receipts
    else
      receipt_arel = Receipt
    end

    if ! params[:means_of_payment].blank?
      receipt_arel = receipt_arel.where('means_of_payment = ?', params[:means_of_payment])
    end

    respond_to do |format|
      format.html do
        if from && to
          receipts = receipt_arel.where('value_date >= ? AND value_date <= ?', from, to).order(:value_date)
          exporter = Exporter::Factory.new( :receipts,
                                            params[:type].to_sym,
                                            { account: params["account"], counterpart_account: params['counterpart_account'] })

          extention = case params[:type]
            when 'banana' then 'txt'
            else 'csv'
          end

          send_data( exporter.export(receipts),
                     type: 'application/octet-stream',
                     filename: "receipts_#{from}_#{to}_#{params[:type]}.#{extention}",
                     disposition: 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to admin_path
        end
      end
    end
  end

  def show
    edit
  end

  def create
    errors = {}

    # Validate params
    [:owner_id, :value_date, :value, :invoice_template_id].each do |k|
      errors[k] = [I18n.t("activerecord.errors.messages.blank")] if params[k].blank?
    end

    if ! params[:affair_id].blank?
      if Affair.exists? params[:affair_id]
        @affair = Affair.find params[:affair_id]

        # no invoice_id should be sent if affair_id is missing or incorrect
        if params[:invoice_id]
          if Invoice.exists?(params[:invoice_id])
            @invoice = Invoice.find(params[:invoice_id])
          else
            errors[:invoice_id] = [I18n.t("permission.errors.record_not_found")]
          end
        end
      else
        errors[:affair_id] = [I18n.t("permission.errors.record_not_found")]
      end
    elsif params[:subscription_id].blank?
      errors[:subscription_id] = [I18n.t("activerecord.errors.messages.blank")]
    else
      # expect to find a subscription if no affair_id is given
      if Subscription.exists? params[:subscription_id]
        @subscription = Subscription.find(params[:subscription_id])
        @affair = Affair.joins(:subscriptions)
                        .where(owner_id: params[:owner_id],
                               subscriptions: {
                                 id: @subscription.id,
                                 title: @subscription.title
                               })
                        .select('affairs.*') # We need this otherwise the returned record is readonly
                        .first
      else
        errors[:subscription_id] = [I18n.t("permission.errors.record_not_found")]
      end
    end

    if errors.empty?
      # Save all objects in a transaction to preserve rollback in case of failure
      Receipt.transaction do
        # Push sequentially in errors hash if validations fails

        # Create an affair if the process of finding one failed
        unless @affair
          @affair = Affair.new( owner_id: params[:owner_id],
                                title: @subscription.title )

          # This will validate and populate receiver_id/buyer_id
          unless @affair.save
            errors = @affair.errors
            raise ActiveRecord::Rollback
          end

          @affair.subscriptions = [ @subscription ]
        end


        # Create an invoice if the process of finding one failed
        unless @invoice
          @invoice = Invoice.new value: @affair.value,
                       created_at: params[:value_date],
                       title: @affair.title,
                       invoice_template_id: params[:invoice_template_id],
                       affair_id: @affair.id
        end

        unless @invoice.save
          errors = @invoice.errors
          raise ActiveRecord::Rollback
        end

        # Finaly create a new receipt
        @receipt = Receipt.new value: params[:value],
                               value_date: params[:value_date],
                               means_of_payment: params[:means_of_payment],
                               invoice_id: @invoice.id
        unless @receipt.save
          errors = @receipt.errors
          raise ActiveRecord::Rollback
        end
      end
    end

    respond_to do |format|
      if errors.empty?
        format.json { render json: @receipt }
      else
        format.json { render json: errors, status: :unprocessable_entity }
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

  def means_of_payments
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @receipts.select('DISTINCT means_of_payment').where("receipts.means_of_payment ~* ?", param)
    end

    respond_to do |format|
      format.json { render json: result.map{|t| {id: nil, label: t.means_of_payment}}}
    end
  end

  def documents

    errors, from, to = validate_export_input(params)

    query = JSON.parse params[:query]
    query.symbolize_keys!
    errors[:search_string] = I18n.t('activerecord.errors.messages.blank') if query[:search_string].blank?

    respond_to do |format|
      if errors.empty?
        people = ElasticSearch.search(query[:search_string], query[:selected_attributes], query[:attributes_order])
        BackgroundTasks::GenerateReceiptsDocumentAndEmail.schedule(people_ids: people.map{ |p| p.id.to_i },
                                                                   person: current_person,
                                                                   from: from,
                                                                   to: to,
                                                                   format: params[:format],
                                                                   generic_template_id: params[:generic_template_id],
                                                                   invoices_filter: params[:invoices_filter],
                                                                   unit_value: params[:unit_value],
                                                                   global_value: params[:global_value],
                                                                   unit_overpaid: params[:unit_overpaid],
                                                                   global_overpaid: params[:global_overpaid])
        format.json { render json: {} }
        format.any do
          # TODO improve report
          flash[:notice] = I18n.t("admin.notices.receipts_generation_started",
            members_count: people.count,
            email: current_person.email)
          redirect_to admin_path(anchor: 'finances')
        end
      else
        format.json do
          render json: errors, status: :unprocessable_entity
        end
        format.any do
          flash[:alert] = I18n.t("directory.errors.query_empty") if errors[:search_string]
          redirect_to admin_path(anchor: 'finances')
        end
      end
    end
  end

  private

  def validate_export_input(params)
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

    if params[:format] != 'csv'
      unless params[:generic_template_id]
        errors[:generic_template_id] = I18n.t("activerecord.errors.messages.blank")
      end
    end

    [errors, from, to]
  end
end
