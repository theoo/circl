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

class SearchAttribute

  class << self

    attr_reader :nested_objects

    def all
      Rails.configuration.search_attributes
    end

    def mapping_for_model(model_name)
      sa = Rails.configuration.search_attributes[model_name.to_sym]

      mapping = sa[:mapping] if sa and sa[:mapping]
      mapping ||= {}

      if sa and sa[:nesting]
        sa[:nesting].each do |name, opts|
        puts opts[:class_name].constantize.inspect
          mapping[name] = {
            type: "object",
            include_in_all: false,
            properties: opts[:class_name].constantize.mapping
          }
        end
      end

      mapping

    end

    def load(path)

      yaml = YAML.load_file(path).deep_symbolize_keys
      Rails.configuration.search_attributes = yaml

      @nested_objects = yaml.each_with_object({}) do |(klass, options), o|
        o[klass.to_sym] = options[:nesting]
      end

    rescue

      raise ArgumentError, "File '#{path}' is missing or invalid. Ensure the YAML file is fixed and restart the app."

    end

  end

end
