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

class OpenSalariesDatatable
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
      iTotalRecords: Salaries::Salary.instance_salaries.unpaid_salaries.count,
      iTotalDisplayRecords: salaries.total_entries,
      aaData: data
    }
  end

  private

  def data
    salaries.map do |salary|
      description = capture_haml do
        haml_tag :b, salary.person.try(:name)
        haml_concat "-"
        haml_tag :i, salary.title
        haml_tag :br
        haml_tag :b, I18n.t("common.from")
        haml_concat salary.from
        haml_tag :b, I18n.t("common.to")
        haml_concat salary.to
      end

      h ={
        0 => salary.id,
        1 => description,
        2 => salary.net_salary.to_view,
        'id' => salary.person_id,
        'number_columns' => [2],
      }

      h
    end
  end

  def salaries
    @salaries ||= fetch_salaries
  end

  def fetch_salaries
    salaries = Salaries::Salary.instance_salaries.unpaid_salaries.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      param = "^#{param}"
      if param.is_i?
        salaries = salaries.where( "salaries.id = ?", param)
      else
        salaries = salaries
          .joins(:person)
          .where( "people.first_name ~* ? OR
                    people.last_name ~* ? OR
                    salaries.title ~* ?",
                    *([param]*3))
      end
    end
    salaries = salaries.page(page).per_page(per_page)
    salaries
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{id title value_in_cents}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
