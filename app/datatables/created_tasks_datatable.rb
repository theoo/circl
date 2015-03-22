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

class CreatedTasksDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  include ApplicationHelper
  include Haml::Helpers

  def initialize(view, person)
    @view = view
    @person = person

    init_haml_helpers
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @person.created_tasks.count,
      iTotalDisplayRecords: tasks.total_entries,
      aaData: data
    }
  end

  private

  def data
    tasks.map do |task|

      description = capture_haml do
        haml_tag :b, task.owner.try(:name)
        haml_concat "-"
        haml_tag :i, task.affair.try(:title)
        haml_tag :br
        if task.description.length > 250
          haml_concat task.description[0...250].gsub(/\n/, "<br />") + "..."
        else
          haml_concat task.description.gsub(/\n/, "<br />")
        end
      end

      duration = capture_haml do
        haml_concat task.duration.to_s + " min"
        haml_tag :br
        haml_concat "(#{task.translated_duration})"
      end

      h ={
        0 => task.id,
        1 => task.start_date,
        2 => task.executer.try(:name),
        3 => description,
        4 => duration,
        'id' => task.id
      }

      h
    end
  end

  def tasks
    @tasks ||= fetch_tasks
  end

  def fetch_tasks
    tasks = @person.created_tasks.order("#{sort_column} #{sort_direction}").limit(100)
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      param = "^#{param}"
      if param.is_i?
        tasks = tasks.where( "tasks.id = ?", param)
      else
        tasks = tasks.where( "tasks.description ~*", param)
      end
    end
    tasks = tasks.page(page).per_page(per_page)
    tasks
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{id created_at executer_id description duration}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
