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

class PermissionsList

  extend Reflection

  # return hash where key is name of controller
  # and value is array of method name
  def self.as_hash
    hash_of_controllers_and_methods
  end

  # returns array of string where string is of kind:
  # controllerName#methodname
  def self.as_array_of_string
    result = []
    hash_of_controllers_and_methods.map do |controller_name, array_of_methods|
      methods = array_of_methods.map { |method_name| "#{controller_name}##{method_name.to_s}" }
      result.concat(methods)
    end
    result
  end

end
