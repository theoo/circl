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

class PeopleDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  include ApplicationHelper
  include Haml::Helpers

  def initialize(view, query, current_person)
    @view = view
    @query = query
    @current_person = current_person

    init_haml_helpers
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: people.count,
      iTotalDisplayRecords: people.total_entries,
      aaData: data
    }
  end

  private

  def data
    people.map do |person|
      h = {}

      @query[:selected_attributes].each_with_index do |attr, index|
        h[index] = highlight(person, attr)
      end

      index = @query[:selected_attributes].size

      h[@query[:selected_attributes].size] = person._score
      h['id'] = person.id
      h
    end
  end

  def people
    @people ||= fetch_people
  end

  def fetch_people
    People.search(@query[:search_string],
      from,
      per_page,
      @query[:selected_attributes],
      @query[:attributes_order],
      @current_person)
  end

  def from
    params[:iDisplayStart].to_i
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

end
