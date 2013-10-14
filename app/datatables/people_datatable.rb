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

      init_haml_helpers
      index = @query[:selected_attributes].size

      h[index + 1] = capture_haml do
        # TODO if can? :change_password, person
        haml_tag  :button,
                  :class => 'btn btn-default',
                  :name => 'directory-person-change-password',
                  :title => I18n.t("directory.views.contextmenu.change_person_password") do
          haml_tag :i, :class => 'icon-key'
        end
      end

      h[index + 2] = capture_haml do
        # TODO if can? :destroy, person
        haml_tag  :button,
                  :class => 'btn btn-danger',
                  :name => 'directory-person-destroy',
                  :title => I18n.t("common.destroy") do
          haml_tag :i, :class => 'icon-remove'
        end
      end

      h[@query[:selected_attributes].size] = person._score
      h['id'] = person.id
      h['action_columns'] = ((index+1)..(index+2))
      h
    end
  end

  def people
    @people ||= fetch_people
  end

  def fetch_people
    ElasticSearch::search_paginated(@query[:search_string], @query[:selected_attributes], @query[:attributes_order], from, per_page, @current_person)
  end

  def from
    params[:iDisplayStart].to_i
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

end
