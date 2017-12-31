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

# This file is the first initializer loaded
# ColorizedOutput will be extended to the whole application
extend ColorizedOutput

# Considering all keys are mandatory

REF_FILE = [Rails.root, "config/configuration.reference.yml"].join("/")
CONFIG_FILE = [Rails.root, "config/configuration.yml"].join("/")

# Check and load configuration.yml file
if File.exists?(CONFIG_FILE)
  @config = YAML.load_file(CONFIG_FILE)
else
  puts red("File config/configuration.yml is missing, please copy \
config/configuration.reference.yml as template and edit values.")
  raise ArgumentError, "File config/configuration.yml is missing."
end

# Check and load configuration.reference.yml file
# Ensure all keys are present in configuration.yml file
if File.exists?(REF_FILE)
  @reference = YAML.load_file(REF_FILE)

  def lookup_keys(branch, context = [])
    branch.each do |k,v|

      current_context = [context, k].flatten
      if eval("@config['" + current_context.join("']['") + "']").nil?
        puts red("Key '#{current_context}' is missing.")
        raise ArgumentError, "Key '#{current_context}' is missing."
      end

      if v.is_a? Hash
        lookup_keys(v, current_context)
      end
    end
  end

  print "Verifing config/configuration.yml: "
  lookup_keys(@reference)
  puts green("done") + "."
else
  puts red("File config/configuration.reference.yml is missing.")
  raise ArgumentError, "File config/configuration.reference.yml is missing."
end

# Override config if env key is present
if ENV["DIR_HOSTNAME"]
  hn = ENV["DIR_HOSTNAME"]
  @config['elasticsearch']['name'] = hn
  @config['elasticsearch']['host'] = "#{hn}.circl.ch"
  @config['elasticsearch']['directory_url'] = "https://#{hn}.circl.ch"
end

@config['mailers']['production']['default']['from']                        = ENV['MAIL_FROM'] if ENV['MAIL_FROM']
@config['mailers']['production']['smtp_settings=']['address']              = ENV['MAIL_ADDRESS'] if ENV['MAIL_ADDRESS']
@config['mailers']['production']['smtp_settings=']['port']                 = ENV['MAIL_PORT'] if ENV['MAIL_PORT']
@config['mailers']['production']['smtp_settings=']['domain']               = ENV['MAIL_DOMAIN'] if ENV['MAIL_DOMAIN']
@config['mailers']['production']['smtp_settings=']['user_name']            = ENV['MAIL_USER_NAME'] if ENV['MAIL_USER_NAME']
@config['mailers']['production']['smtp_settings=']['password']             = ENV['MAIL_PASSWORD'] if ENV['MAIL_PASSWORD']
@config['mailers']['production']['smtp_settings=']['authentication']       = ENV['MAIL_AUTHENTICATION'] if ENV['MAIL_AUTHENTICATION']
@config['mailers']['production']['smtp_settings=']['enable_starttls_auto'] = ENV['MAIL_ENABLE_STARTTLS_AUTO'] if ENV['MAIL_ENABLE_STARTTLS_AUTO']

@config['elasticsearch']['url'] = ENV['ES_URL'] if ENV['ES_URL']
# @config['redis']['environments']['production'] = ENV['REDIS_URL'] if ENV['REDIS_URL']

# Everything went fine, load config
Rails.configuration.settings = @config

