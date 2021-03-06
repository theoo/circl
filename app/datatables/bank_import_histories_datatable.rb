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

class BankImportHistoriesDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: BankImportHistory.count,
      iTotalDisplayRecords: bank_import_histories.total_entries,
      aaData: data
    }
  end

  private

  def data
    bank_import_histories.map do |bank_import_history|

      dl = bank_import_history.decoded_line
      details = [
        I18n.t("bank_import_history.views.account")       + ": #{dl[:account]}",
        I18n.t("bank_import_history.views.owner")         + ": #{Person.find(dl[:owner_id]).full_name} (#{dl[:owner_id]})",
        I18n.t("bank_import_history.views.invoice")       + ": #{dl[:invoice_id]}",
        I18n.t("bank_import_history.views.invoice_date")  + ": #{dl[:invoice_date]}",
        I18n.t("bank_import_history.views.receipt_value") + ": #{Money.new(dl[:value_in_cents]).to_view}",
        I18n.t("bank_import_history.views.date_entry")    + ": #{dl[:date_entry]}",
        I18n.t("bank_import_history.views.date_write")    + ": #{dl[:date_write]}",
        I18n.t("bank_import_history.views.date_value")    + ": #{dl[:date_value]}"
      ].join("<br />")

      ref_line = ""
      if not bank_import_history.account_servicer_reference.nil?
        # xml = Nokogiri::XML bank_import_history.reference_line
        ref_line += "XML Document"
      else
        ref_line += "<code>"
        ref_line += bank_import_history.reference_line
        ref_line += "</code>"
      end

      {
        0 => bank_import_history.file_name,
        1 => bank_import_history.media_date,
        2 => ref_line,
        'id' => bank_import_history.id,
        'title' => details
      }
    end
  end

  def bank_import_histories
    @bank_import_histories ||= fetch_bank_import_histories
  end

  # TODO: improve search like "Firstname Lastname", actually returns zero results.
  def fetch_bank_import_histories
    bih = BankImportHistory.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      bih = bih.where("bank_import_histories.reference_line ~* ?
                       OR bank_import_histories.file_name ~* ?", *([param] * 2))
    end
    bih = bih.page(page).per_page(per_page)
    bih
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{file_name media_date reference_line}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
