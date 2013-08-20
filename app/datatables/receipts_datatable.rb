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

class ReceiptsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Receipt.count,
      iTotalDisplayRecords: receipts.total_entries,
      aaData: data
    }
  end


  private

  def data
    receipts.map do |receipt|
      {
        0 => receipt.id,
        1 => receipt.owner.name,
        2 => receipt.affair.title,
        3 => receipt.invoice.value.to_view,
        4 => receipt.value.to_view,
        5 => receipt.value_date,
        6 => receipt.created_at,
        'id' => receipt.id,
        'actions' => [ I18n.t('receipt.views.contextmenu.edit_receipt') ],
        'number_columns' => [3,4]
      }
    end
  end

  def receipts
    @receipts ||= fetch_receipts
  end

  def fetch_receipts
    receipts = Receipt.select('receipts.*,
                               (SELECT CONCAT(last_name, first_name) from people where id = affairs.owner_id) as owner_name,
                               affairs.title as affair_title,
                               invoices.value_in_cents as value')
                      .joins(:invoice => { :affair => :owner })
                      .group('receipts.id, invoices.id, affairs.id')
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      if param.is_i?
        receipts = receipts.where("receipts.id = ?", param)
      else
        receipts = receipts.where("people.last_name #{SQL_REGEX_KEYWORD} ? OR
                                   people.first_name #{SQL_REGEX_KEYWORD} ? OR
                                   affairs.title #{SQL_REGEX_KEYWORD} ?",
                                   *([param] * 3))
      end
    end
    receipts = receipts.order("#{sort_column} #{sort_direction}")
    receipts = receipts.page(page).per_page(per_page)
    receipts
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{id owner_name affair_title invoice_value value value_date created_at}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
