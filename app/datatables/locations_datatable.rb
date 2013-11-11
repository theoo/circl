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

class LocationsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Location.count,
      iTotalDisplayRecords: locations.total_entries,
      aaData: data
    }
  end


  private

  def data
    locations.map do |location|
      {
        0 => location.name,
        1 => location.parent.try(:name),
        2 => location.iso_code_a2,
        3 => location.postal_code_prefix,
        4 => location.phone_prefix,
        'id' => location.id,
        'actions' => [ I18n.t('location.views.actions.edit_location'),
                       I18n.t('location.views.actions.destroy_location') ],
        'number_columns' => [2,3,4]
      }
    end
  end

  def locations
    @locations ||= fetch_locations
  end

  def fetch_locations
    locations = Location.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      param = "^#{param}"
      locations = locations.where("locations.postal_code_prefix #{SQL_REGEX_KEYWORD} ? OR
                                   locations.name #{SQL_REGEX_KEYWORD} ?",
                                   *([param]*2))
    end
    locations = locations.page(page).per_page(per_page)
    locations
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{name parent_id iso_code_a2 postal_code_prefix phone_prefix}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
