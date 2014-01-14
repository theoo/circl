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

class InvoicesDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Invoice.count,
      iTotalDisplayRecords: invoices.total_entries,
      aaData: data
    }
  end


  private

  def data
    invoices.map do |invoice|
      {
        0 => invoice.id,
        1 => invoice.buyer.name,
        2 => invoice.title,
        3 => invoice.value.to_view,
        4 => invoice.get_statuses.map{|s| I18n.t("invoice.views.statuses." + s.to_s)}.join(", "),
        5 => invoice.created_at,
        'id' => invoice.id,
        'number_columns' => [3]
      }
    end
  end

  def invoices
    @invoices ||= fetch_invoices
  end

  def fetch_invoices
    invoices = Invoice.select('invoices.*')
                      .joins(:affair => :owner)
                      .group('invoices.id, affairs.id')
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      if param.is_i?
        invoices = invoices.where("invoices.id = ?", param)
      else
        invoices = invoices.where("people.last_name ~* ? OR
                                   people.first_name ~* ? OR
                                   affairs.title ~* ?",
                                   *([param] * 3))
      end
    end
    invoices = invoices.order("#{sort_column} #{sort_direction}")
    invoices = invoices.page(page).per_page(per_page)
    invoices
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{id affairs.buyer_id title value_in_cents status created_at}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
