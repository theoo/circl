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

class Admin::BankImportHistoriesController < ApplicationController

  layout false

  def index
    authorize! :index, BankImportHistory
    respond_to do |format|
      format.json { render json: BankImportHistoriesDatatable.new(view_context) }
    end
  end

  def confirm
    authorize! :confirm, BankImportHistory

    unless params[:receipts_file]
      flash[:alert] = I18n.t('admin.errors.no_file_submitted')
      redirect_to admin_path(anchor: 'finances')
      return
    end

    @infos = BankImporter::Postfinance.parse_receipts(params[:receipts_file].read)
    @file_name = params[:receipts_file].original_filename

    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  # TODO check required keys: receipts, errors and summary
  def import
    authorize! :import, BankImportHistory

    if params[:receipts]
      receipts = params[:receipts].select{ |info| info[:selected] }

      file_date = Date.parse(params[:summary][:media_date])
      file_name = params[:summary][:file_name]

      Receipt.transaction do
        receipts.each do |info|

          # keep a track of each imported lines
          BankImportHistory.create!(file_name: file_name,
                                    media_date: file_date,
                                    reference_line: info[:line] )

          tmp = info.dup
          if info[:rectification] == 'true'
            r = Receipt.find(tmp[:receipt_id])
            r.value_in_cents = tmp[:value_in_cents]
            r.save!
          else
            %w{ line_number line owner_id receipt_id selected
              already_imported rectification old_value_in_cents }.each{ |s| tmp.delete(s) }
            info[:receipt_id] = Receipt.create!(tmp).id
          end
        end
      end

      PersonMailer.send_receipts_import_report( current_person.id,
        params[:receipts],
        params[:errors]).deliver
      flash[:notice] = I18n.t('admin.notices.receipts_imported', email: current_person.email)
      redirect_to admin_path(anchor: 'finances')

    else

      flash[:error] = I18n.t('receipt.errors.no_receipts_selected')
      redirect_to admin_path(anchor: 'finances')

    end

  end

  def export
    authorize! :export, BankImportHistory

    from = Date.parse(params[:from]) if validate_date_format(params[:from])
    to   = Date.parse(params[:to]) if validate_date_format(params[:to])

    @bihs = BankImportHistory.where("media_date BETWEEN ? AND ?", from, to)

    @bihs = @bihs.map do |bih|
      dl = bih.decoded_line
      dl.merge!(bih.attributes)
      OpenStruct.new dl
    end

    respond_to do |format|
      format.json { render json: @bihs }
      format.csv do
        fields = []
        fields << 'account'
        fields << 'owner_name'
        fields << 'invoice_id'
        fields << 'invoice_date'
        fields << 'date_entry'
        fields << 'date_write'
        fields << 'date_value'
        fields << 'value'
        fields << 'file_name'
        fields << 'media_date'
        fields << 'reference_line'
        render inline: csv_ify(@bihs, fields)
      end
    end
  end

end
