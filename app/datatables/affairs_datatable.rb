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

class AffairsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Affair.count,
      iTotalDisplayRecords: affairs.total_entries,
      aaData: data
    }
  end

  private

  def data
    affairs.map do |affair|

      classes = []
      # Colorize active affairs
      if ! affair.has_status?(:cancelled) \
        and ! affair.has_status?(:offered) \
        and ! affair.has_status?(:paid)
        classes.push("success") unless affair.estimate
        classes.push("warning") if affair.estimate
      end

      {
        0 => affair.id,
        1 => affair.title,
        2 => [I18n.t("affair.views.owner")  + ": " + affair.owner.name,
              I18n.t("affair.views.buyer")  + ": " + affair.buyer.name,
              I18n.t("affair.views.receiver") + ": " + affair.receiver.name].join("<br />"),
        3 => affair.invoices_count, # sql shortcut
        4 => affair.receipts_count, # sql shortcut
        5 => affair.invoices_sum.to_money.to_view, # sql shortcut
        6 => affair.receipts_sum.to_money.to_view, # sql shortcut
        7 => affair.translated_statuses,
        8 => affair.created_at,
        'id' => affair.id,
        'actions' => [ I18n.t('affair.views.actions.edit_affair') ],
        'classes' => classes.join(" "),
        'number_columns' => [5,6,7,8]
      }
    end
  end

  def affairs
    @affairs ||= fetch_affairs
  end

  # TODO: improve search like "Firstname Lastname", actually returns zero results.
  def fetch_affairs
    affairs = Affair.select('affairs.*,
                            COUNT(invoices.id) as invoices_count,
                            COUNT(receipts.id) as receipts_count,
                            COALESCE(SUM(invoices.value_in_cents)/100.0, 0.0) as invoices_sum,
                            COALESCE(SUM(receipts.value_in_cents)/100.0, 0.0) as receipts_sum')
                    .joins('LEFT JOIN invoices ON invoices.affair_id = affairs.id')
                    .joins('LEFT JOIN receipts ON receipts.invoice_id = invoices.id')
                    .joins(:owner)
                    .group('affairs.id, people.last_name')
    affairs = affairs.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      if param.is_i?
        affairs = affairs.where("affairs.id = ?", param)
      else
        affairs = affairs.where("affairs.title ~* ?
                                 OR people.first_name ~* ?
                                 OR people.last_name ~* ?", *([param] * 3))
      end
    end
    affairs = affairs.page(page).per_page(per_page)
    affairs
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = [ :id,
                :title,
                'people.last_name',
                :invoices_count,
                :receipts_count,
                :invoices_sum,
                :receipts_sum,
                :status,
                :created_at ]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
