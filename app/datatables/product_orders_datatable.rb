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
    warning_date = Time.now + ApplicationSetting.value("product_item_warning_threshold")
    danger_date = Time.now + ApplicationSetting.value("product_item_danger_threshold")

    product_items.map do |product_item|

      # Colorize active product_items
      classes = []
      if product_item.delivery_at and not product_item.confirmed_at
        if product_item.delivery_at < danger_date
          classes.push("danger")
        elsif product_item.delivery_at < warning_date
          classes.push("warning")
        elsif product_item.ordered_at
          classes.push("info")
        end
      elsif product_item.confirmed_at
        classes.push("success")
      end

      description = capture_haml do
        haml_tag :b, product_item.product.try(:title)
        if ! product_item.product.try(:description).try(:blank?)
          haml_tag :br if product_item.product.title
          if product_item.product and product_item.product.description.size > 255
            haml_concat product_item.product.description.exerpt
          else
            haml_concat product_item.product.description
          end
        end
        if ! product_item.comment.blank?
          haml_tag :br
          haml_tag :code, product_item.comment
        end
      end

      affair_description = capture_haml do
        haml_tag :b, product_item.affair.try(:title)
        haml_tag :i, product_item.affair.try(:id)
        haml_tag :br
        if product_item.affair and product_item.affair.description.size > 255
          haml_concat product_item.affair.description.exerpt
        else
          haml_concat product_item.affair.description
        end
      end

      {
        0 => product_item.created_at.try(:to_date), # localization
        1 => product_item.ordered_at.try(:to_date), # localization
        2 => product_item.confirmed_at.try(:to_date), # localization
        3 => product_item.delivery_at.try(:to_date), # localization
        4 => product_item.quantity,
        5 => description,
        6 => affair_description,
        7 => product_item.product.try(:provider).try(:name), # link
        8 => product_item.affair.try(:seller).try(:name),
        'id' => product_item.affair.try(:id),
        'classes' => classes.join(" "),
        'number_columns' => [4]
      }
    end
  end

  def product_items
    @product_items ||= fetch_product_items
  end

  # TODO: improve search like "Firstname Lastname", actually returns zero results.
  def fetch_product_items
    product_items = AffairsProductsProgram.joins(:affair, :category, :product, :program)
    product_items = product_items.order("#{sort_column} #{sort_direction} NULLS last")
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
    columns = [ :created_at,
                :ordered_at,
                :confirmed_at,
                :delivery_at,
                'products.title',
                'affairs.title',
                'products.provider_id',
                'affairs.seller_id']
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
