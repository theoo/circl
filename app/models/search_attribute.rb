class SearchAttribute

  extend ColorizedOutput

  class << self

    def all
      Rails.configuration.search_attributes
    end

    def load(path)

      yaml = YAML.load_file(path).deep_symbolize_keys
      Rails.configuration.search_attributes = yaml

    rescue Exception => e

      puts red("File '#{path}' is missing or invalid. Ensure the YAML file is fixed and restart the app.")
      raise e

    end

    def mappings

      all.each_with_object({}) do |(class_name, sa), o|

        m = sa[:mapping] if sa and sa[:mapping]
        m ||= {}

        if sa and sa[:nesting]
          sa[:nesting].each do |name, opts|
            m[name] = {
              type: "object",
              include_in_all: false,
              properties: opts[:class_name].constantize.mapping
            }
          end
        end

        o[class_name] = m

      end

    end

    def nested_objects
      all.each_with_object({}) do |(class_name, options), o|
        o[class_name.to_sym] = options[:nesting]
        o[class_name.to_sym] ||= []
      end
    end

  end

end
