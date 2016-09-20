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

module SearchEngine

  extend ActiveSupport::Concern

  included do

    model_name = (self.is_a?(Module) ? name : self.class.name).to_s

    include Elasticsearch::Model

    settings do

      # index            Rails.configuration.settings['elasticsearch']['index']
      index_name       Rails.configuration.settings['elasticsearch']['name']
      document_type    model_name.downcase

      mappings dynamic: false do

        if SearchAttribute.mapping_for_model(model_name)

          SearchAttribute.mapping_for_model(model_name).each do |attribute, opt|
            indexes attribute, opt[:mapping]
          end

        end

      end

    end

  end

  # after_commit on: [:create] do
  #   __elasticsearch__.index_document if self.published?
  # end

  # after_commit on: [:update] do
  #   __elasticsearch__.update_document if self.published?
  # end

  # after_commit on: [:destroy] do
  #   __elasticsearch__.delete_document if self.published?
  # end

  def update_search_engine(object = nil)

    return unless Rails.configuration.settings['elasticsearch']['enable_indexing']

    person = self
    person = object if object and object.is_a? Person

    if person.new_record? # If validation failed, it may try to update anyways.
      return false # returning false should prevent association from beeing saved.
    else
      Synchronize::SearchEngineJob.perform_later(ids: person.id)
    end

  end

end