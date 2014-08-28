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

class ProductsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Product.count,
      iTotalDisplayRecords: products.total_entries,
      aaData: data
    }
  end

  private

  def data
    products.map do |product|
      classes = []
      classes.push("success") unless product.archive
      {
        0 => product.id,
        1 => product.key,
        2 => "<b>" + product.title + "</b><br/>" + product.description,
        3 => product.variants.count,
        4 => product.category,
        5 => product.updated_at,
        'id' => product.id,
        'number_columns' => [3],
        'classes' => classes.join(" ")
      }
    end
  end

  def products
    @products ||= fetch_products
  end

  def fetch_products
    products = Product.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      param = "^#{param}"
      products = products.where( "products.key ~* ? OR
                                  products.title ~* ? OR
                                  products.description ~* ?",
                                  *([param]*3))
    end
    products = products.page(page).per_page(per_page)
    products
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    # TODO: Order variants
    columns = %w{id key description id category updated_at}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
