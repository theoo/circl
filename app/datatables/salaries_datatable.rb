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

class SalariesDatatable
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
      iTotalRecords: Salaries::Salary.count,
      iTotalDisplayRecords: salaries.total_entries,
      aaData: data
    }
  end

  private

  def data
    salaries.map do |salary|
      classes = []
      classes.push("success") if salary.paid? and not salary.is_reference
      classes.push("warning") if salary.is_reference
      h ={
        0 => salary.id,
        1 => salary.person.try(:name),
        2 => salary.title,
        3 => salary.from,
        4 => salary.to,
        5 => salary.gross_pay.to_f,
        6 => salary.net_salary.to_f,
        7 => salary.created_at,
        'id' => salary.id,
        'number_columns' => [5, 6],
        'classes' => classes.join(" "),
        'action_columns' => [4, 5, 8, 9, 10, 11]
      }

      if salary.is_reference
        h[8] = capture_haml do
          haml_tag  :a,
                    :class => 'btn btn-default',
                    :name => 'salary-copy',
                    :title => I18n.t('salary.views.actions.copy_reference') do
            haml_tag :i, :class => 'icon-copy'
          end
        end
      else
        h[8] = ""
      end

      if ! salary.paid?
        h[9] = capture_haml do
          haml_tag  :a,
                    :class => 'btn btn-default',
                    :name => 'salary-check-as-paid',
                    :title => I18n.t('salary.views.actions.check_as_paid') do
            haml_tag :i, :class => 'icon-ok'
          end
        end
      else
        h[9] = ""
      end

      if ! salary.is_reference
        h[10] = capture_haml do
          haml_tag  :a,
                    :class => 'btn btn-default',
                    :name => 'salary-download',
                    :title => I18n.t('common.download') do
            haml_tag :i, :class => 'icon-download'
          end
        end
      else
        h[10] = ""
      end

      if salary.children.count == 0
        h[11] = capture_haml do
          haml_tag  :a,
                    :class => 'btn btn-danger',
                    :name => 'salary-destroy',
                    :title => I18n.t('common.destroy') do
            haml_tag :i, :class => 'icon-remove'
          end
        end
      else
        h[11] = ""
      end

      h
    end
  end

  def salaries
    @salaries ||= fetch_salaries
  end

  def fetch_salaries
    salaries = Salaries::Salary.order("#{sort_column} #{sort_direction}")
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
    columns = %w{id person_id title salaries.from salaries.to id id created_at id id id id}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
