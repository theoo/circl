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

class OpenAffairsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  include ApplicationHelper
  include Haml::Helpers

  def initialize(view)
    @view = view

    init_haml_helpers
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Affair.effectives.open.count,
      iTotalDisplayRecords: affairs.total_entries,
      aaData: data
    }
  end

  private

  def data
    affairs.map do |affair|

      description = capture_haml do
        haml_tag :b, affair.owner.try(:name)
        haml_concat "-"
        haml_tag :i, affair.title
        if ! affair.description.blank?
          haml_tag :br
          haml_concat affair.description.gsub(/\n/, "<br />")
        end

        if affair.subscriptions.count > 0
          haml_tag :br
          haml_tag ".badge", affair.subscriptions_count
          haml_concatI18n.t('affair.views.subscriptions') + " :"
          haml_concat affair.subscriptions_value.to_view
        end

        if affair.tasks.count > 0
          haml_tag :br
          haml_tag ".badge", affair.tasks.count
          haml_concat I18n.t('affair.views.tasks') + " :"
          haml_concat affair.tasks_value.to_view
        end

        if affair.products.count > 0
          haml_tag :br
          haml_tag ".badge", affair.product_items.count
          haml_concat I18n.t('affair.views.products') + " :"
          haml_concat affair.product_items_value.to_view
        end

        if affair.extras.count > 0
          haml_tag :br
          haml_tag ".badge", affair.extras.count
          haml_concat I18n.t('affair.views.extras') + " :"
          haml_concat affair.extras_value.to_view
        end

        haml_tag :br
        haml_tag ".badge", affair.invoices.count
        haml_concat I18n.t('affair.views.invoices') + " :"
        haml_concat affair.invoices_value.to_view

        haml_tag :br
        haml_tag ".badge", affair.receipts.count
        haml_concat I18n.t('affair.views.receipts') + " :"
        haml_concat affair.receipts_value.to_view
      end

      # TODO do not cut in a middle of a word
      small_description = description.size > 500 ? description[0..500] + "..." : description

      {
        0 => affair.id,
        1 => affair.updated_at,
        2 => small_description,
        'id' => affair.owner_id
      }
    end
  end

  def affairs
    @affairs ||= fetch_affairs
  end

  # TODO: improve search like "Firstname Lastname", actually returns zero results.
  def fetch_affairs
    affairs = Affair.effectives.open.joins(:owner)
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
    columns = [ :id, :updated_at, :title ]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
