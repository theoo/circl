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

module ElasticSearch

  def self.search(search_string, selected_attributes=[], attributes_order=[], current_person=nil)
    results = []
    from = 0
    per_page = Rails.configuration.settings['elasticsearch']['max_per_page']
    while true
      tmp = search_paginated(search_string, from, per_page, selected_attributes, attributes_order,  current_person)
      break unless tmp.size > 0
      results += tmp.to_a
      from += per_page
    end
    results
  end

  def self.count(search_string, current_person = nil)
    search = Tire::Search::Search.new(Rails.configuration.settings['elasticsearch']['name'])
    search_string = exclude_hidden(search_string)
    search.query { string search_string }
    search.size Rails.configuration.settings['elasticsearch']['max_per_page']
    search.filter :terms, { :accessible_by => current_person.roles.map(&:name) } if current_person
    search.results.size
  end

  def self.search_paginated(search_string, from, per_page, selected_attributes=[], attributes_order=[], current_person=nil)
    search = Tire::Search::Search.new(Rails.configuration.settings['elasticsearch']['name'])

    search_string = '*' if search_string.blank?

    search_string = exclude_hidden(search_string)

    search.query { string search_string }
    search.sort do
      if attributes_order && attributes_order.size > 0
        attributes_order.each do |h|
          by "#{h.keys.first}.sort", h.values.first
        end
      end
      by '_score', 'desc'
    end
    search.highlight *selected_attributes, :options => { :tag => '<b>' }
    search.from(from)
    search.size(per_page)
    search.filter :terms, { :accessible_by => current_person.roles.map(&:name) } if current_person
    search.results
  end

  # FIXME This should not be accessible from outside of the class
  def self.exclude_hidden(search_string)
    # exclude "hidden" people by default.
    # This can be overrided by setting explicitly "AND hidden:true" or "AND hidden:all"
    all_regex = /AND\shidden\:["']?all["']?/
    if search_string.match(all_regex)
      search_string = search_string.gsub(all_regex, '').strip
    elsif ! search_string.match(/AND\shidden\:["']?true["']?/)
      search_string = "(" + search_string + ") AND hidden:false"
    end
    search_string
  end

  module Mapping

    def self.included(base)

      base.class_eval { include Tire::Model::Search }
      return unless base.table_exists? && SearchAttribute.table_exists?

      base.class_eval do
        create_mapping = proc do
          return if Rails.configuration.settings['elasticsearch']['enable_indexing'] == false
          SearchAttribute.where(:model => base.to_s).each do |attr|
            begin
              # Should be a hash in order to work. But mappings are editable through the user's iface.
              if attr.mapping.is_a? Hash
                h = attr.mapping.symbolize_keys
                # TODO recurse into hash and change all :properties
                if h[:type] == 'object' and !h[:properties].is_a?(Hash)
                  h[:properties] = eval(h[:properties])
                end
                indexes attr.name, h
              end
            rescue Exception => e
              extend ColorizedOutput

              msg = "Failed to index #{attr.inspect}, error raised: #{e.inspect}"
              puts red(msg)
              logger.warn msg
            end
          end
        end

        if base.to_s == 'Person'
          yaml = Rails.configuration.settings['elasticsearch']
          base.index_name(yaml['name'])
          settings(yaml['index']) do
            mapping &create_mapping
          end
        else
          create_mapping.call
        end
      end
    end
  end

  module Indexing

    def self.included(base)
      return unless base.table_exists? && SearchAttribute.table_exists?
      base.class_eval do

        attrs = SearchAttribute.where(:model => base.to_s).map do |attr|
          [attr.name, attr.indexing]
        end

        create_index = proc do
          attrs.each_with_object({}) do |arr, h|
            h[arr.first] = eval(arr.last)
          end
        end

        define_method(:as_indexed_json, &create_index)

        def to_indexed_json
          return if Rails.configuration.settings['elasticsearch']['enable_indexing'] == false
          as_indexed_json.to_json
        end

        # used by HABTM after_add/remove callbacks
        def update_elasticsearch_index(object)
          return if Rails.configuration.settings['elasticsearch']['enable_indexing'] == false
          person = self
          person = object if object and object.is_a? Person

          if person.new_record? # If validation failed, it may try to update anyways.
            return false # returning false should prevent association from beeing saved.
          else
            BackgroundTasks::UpdateIndexForPeople.schedule(:people_ids => [person.id])
          end
        end

      end
    end

  end

  module AutomaticPeopleReindexing
    def self.included(base)
      return if Rails.configuration.settings['elasticsearch']['enable_indexing'] == false
      base.class_eval do
        before_destroy :reindex_people
        after_save :reindex_people_if_needed

        def reindex_people_if_needed
          reindex_people unless self.changes.empty?
          true
        end

        def reindex_people
          BackgroundTasks::UpdateIndexForPeople.schedule(:people_ids => people.map(&:id)) if people.count > 0
          true
        end
      end
    end
  end
end
