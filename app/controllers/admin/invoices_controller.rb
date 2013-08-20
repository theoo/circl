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

  layout false

  load_and_authorize_resource :except => :index

  def index
    authorize! :index, Invoice
    respond_to do |format|
      format.json { render :json => InvoicesDatatable.new(view_context) }
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
          invoices = Invoice.where('created_at >= ? AND created_at <= ?', from, to).order(:created_at)
          exporter = Exporter::Factory.new( :invoices,
                                            params[:type].to_sym,
                                            { :account => params["account"], :counterpart_account => params['counterpart_account'] })
          send_data( exporter.export(invoices),
                     :type => 'application/octet-stream',
                     :filename=> "invoices_#{from}_#{to}_#{params[:type]}.csv",
                     :disposition => 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to admin_path
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render :json => @invoice }
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @invoices.where("invoices.title #{SQL_REGEX_KEYWORD} ?", param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.title}}}
    end
  end

end
