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

module SearchEngineConcern

  extend ActiveSupport::Concern

  included do

    model_name = (self.is_a?(Module) ? name : self.class.name).to_s

    include Elasticsearch::Model

    settings do

      # index            Rails.configuration.settings['elasticsearch']['index']
      index_name       Rails.configuration.settings['elasticsearch']['name']
      document_type    model_name.downcase

      mappings dynamic: false do

        mappingz = SearchAttribute.mappings[model_name.to_sym]
        if mappingz

          mappingz.each do |attribute, opt|
            indexes attribute, opt
          end

        elsif self.class.to_s != Elasticsearch::Model::Indexing::Mappings

          puts "SearchEngineConcern is included in #{self.class.to_s} Model but the mapping \
is not defined in config/search_attributes.yml."

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

  #
  # Method used by ElasticSearch to retrive document
  # @param options = {} [Hash] JSON options
  #
  # @return [Hash] for ElasticSearch document
  def as_indexed_json(options = {})

    class_sym = self.class.to_s.to_sym

    if defined?(super)
      h = super(options)
    else
      mappingz = SearchAttribute.mappings[class_sym]
      if mappingz
        options.merge!(only: mappingz.keys)
        h = as_json(options)
      else
        h = {}
      end
    end

    nested_objects = SearchAttribute.nested_objects[class_sym]
    if nested_objects

      nested_objects.each do |attribute, options|
        if self.respond_to?(options[:indexing])
          relation = self.send(options[:indexing])
          if relation.send("respond_to?", :as_indexed_json)
            h[attribute] = relation.as_indexed_json
          else
            h[attribute] = relation.as_json
          end
        else
          raise ArgumentError, "#{options[:indexing]} doesn't exists."
        end
      end

    else

      puts "SearchEngineConcern is included in #{self.class.to_s} Model but the nesting is not defined \
in config/search_attributes.yml."

    end

    h
  end

  #
  # Update ElasticSearch document
  # @param object = nil [Class] any ActiveRecord object
  #
  # @return [Boolean] false if object validation fails
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