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

class ProductOrdersDatatable
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
      iTotalRecords: AffairsProductsProgram.count,
      iTotalDisplayRecords: product_items.total_entries,
      aaData: data
    }
  end

  private

  def data
    product_items.map do |product_item|

      classes = []
      # Colorize active product_items
      # if not product_item.has_status?([:paid, :overpaid])
      #   if not product_item.estimate and product_item.unbillable
      #     classes.push("danger")
      #   elsif product_item.estimate
      #     classes.push("warning")
      #   else
      #     if product_item.has_status?([:cancelled, :offered])
      #       classes.push("info")
      #     else
      #       classes.push("success")
      #     end
      #   end
      # end

      {
        0 => product_item.delivery_at, # localization
        1 => product_item.product.try(:title),
        2 => [ "(", product_item.affair.try(:id), ") ", product_item.affair.try(:title)].join(""), # link
        3 => product_item.product.try(:provider).try(:name), # link
        4 => product_item.affair.try(:seller).try(:name),
        'id' => product_item.id,
        # 'actions' => [ I18n.t('product_item.views.actions.edit_product_item') ],
        'classes' => classes.join(" ")
        # 'number_columns' => [3,4,5]
      }
    end
  end

  def product_items
    @product_items ||= fetch_product_items
  end

  # TODO: improve search like "Firstname Lastname", actually returns zero results.
  def fetch_product_items
    product_items = AffairsProductsProgram.joins(:affair, :category, :product, :program)
    product_items = product_items.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      product_items = product_items.where("affairs.title ~* ?
                               OR affairs_products_categories.title ~* ?
                               OR products.title ~* ?
                               OR product_programs.title ~* ?", *([param] * 4))
    end
    product_items = product_items.page(page).per_page(per_page)
    product_items
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = [ :id,
                :id,
                :id,
                :id,
                :id]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
