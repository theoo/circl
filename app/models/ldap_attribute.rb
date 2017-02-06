class LdapAttribute

  class << self

    def mapping
      Rails.configuration.ldap_attributes
    end

    def load(path)

      yaml = YAML.load_file(path)
      Rails.configuration.ldap_attributes = yaml

    rescue

      raise ArgumentError, "File '#{path}' is missing or invalid. Ensure the YAML file is fixed and restart the app."

    end

  end

end
