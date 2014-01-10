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

# Ensure all required key exists in ApplicationSetting
extend ColorizedOutput

required_binaries = %w{ wkhtmltopdf wkhtmltoimage lowriter convert }

print "Verifing Externalities: "
required_binaries.each do |b|
  unless system("which #{b} > /dev/null 2>&1")
    message = "Binary '#{b}' not found!"
    puts red(message)
    raise ArgumentError, message
  end
end
puts green("done") + "."
