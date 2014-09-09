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

class PersonCommentsDatatable
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
      iTotalRecords: @person.comments_edited_by_others.count,
      iTotalDisplayRecords: comments.total_entries,
      aaData: data
    }
  end

  private

  def data
    comments.map do |comment|

      description = capture_haml do
        haml_tag :b, comment.title
        haml_tag :br
        haml_concat comment.description
      end

      classes = []
      if ! comment.is_closed
        classes << 'success'
      end

      h ={
        0 => comment.created_at,
        1 => comment.person.try(:name),
        2 => description,
        'id' => comment.id,
        'classes' => classes.join(" ")
      }

      h
    end
  end

  def comments
    @comments ||= fetch_comments
  end

  def fetch_comments
    comments = @person.comments_edited_by_others
      .order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      param = "^#{param}"
      if param.is_i?
        comments = comments.where( "comments.id = ?", param)
      else
        comments = comments
          .where( "comments.description ~* ? OR
                    comments.title ~* ?",
                    *([param]*2))
      end
    end
    comments = comments.page(page).per_page(per_page)
    comments
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{created_at person_id title}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
