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

class CreditorsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  include ApplicationHelper
  include Haml::Helpers

  def initialize(view, subset = nil)
    @view = view
    @subset = subset

    init_haml_helpers
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Creditor.count,
      iTotalDisplayRecords: creditors.total_entries,
      aaData: data
    }
  end

  private

  def data
    creditors.map do |creditor|

      classes = []
      # Colorize active creditors
      if creditor.late?
        classes.push("danger")
      elsif creditor.discount_late?
        classes.push("warning")
      elsif creditor.paid?
        classes.push("success")
      end

      value = creditor_value_summary(creditor)
      discount = creditor_discount_value_and_date(creditor)

      {
        0 => creditor.created_at,
        1 => creditor.title,
        2 => creditor.creditor.try(:name),
        3 => value,
        4 => I18n.l(creditor.invoice_received_on),
        5 => discount,
        6 => creditor.invoice_ends_on,
        7 => creditor.invoice_in_books_on,
        8 => creditor.paid_on,
        9 => creditor.payment_in_books_on,
        10 => nil,
        'id' => creditor.id,
        'classes' => classes.join(" "),
        'number_columns' => [3]
      }
    end
  end

  def creditors
    @creditors ||= fetch_creditors
  end

  # TODO: improve search like "Firstname Lastname", actually returns zero results.
  def fetch_creditors
    @subset ||= Creditor
    _creditors = @subset.joins(:creditor)
    _creditors = _creditors.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      if param.is_i?
        _creditors = _creditors.where("creditors.id = ?", param)
      else
        _creditors = _creditors.where("creditors.title ~* ?
                                 OR creditors.description ~* ?
                                 OR people.organization_name ~* ?
                                 OR people.first_name ~* ?
                                 OR people.last_name ~* ?", *([param] * 5))
      end
    end
    _creditors = _creditors.page(page).per_page(per_page)
    _creditors
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = [ :created_at,
      :title,
      "people.organization_name",
      :value_in_cents,
      :invoice_received_on,
      :discount_ends_on,
      :invoice_ends_on,
      :invoice_in_books_on,
      :paid_on,
      :payment_in_books_on,
      :created_at ]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
