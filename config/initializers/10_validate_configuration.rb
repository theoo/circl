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

# Everything went fine, load config
Rails.configuration.settings = @config
