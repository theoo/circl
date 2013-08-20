if Rails.configuration.settings.has_key?('ldap')
  Rails.configuration.ldap_admin   = Net::LDAP.new(Rails.configuration.settings['ldap']['admin'].deep_symbolize_keys)
  Rails.configuration.ldap_config  = Net::LDAP.new(Rails.configuration.settings['ldap']['config'].deep_symbolize_keys)
  Rails.configuration.ldap_enabled = Rails.configuration.settings['ldap']['enabled'] == true
else
  Rails.logger.info 'configuration.yml: not loading ldap because configuration is missing.'
  Rails.configuration.ldap_enabled = false
end
