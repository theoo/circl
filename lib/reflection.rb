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

module Reflection

  # returns an array of strings
  # representing the names of the models
  def list_model_names
    list_of_(:models)
  end

  # returns an array of strings
  # representing the names of the controllers
  def list_controller_names
    list_of_(:controllers)
  end

  # returns hash of controllers which have defined methods
  # where key -> controller name, value -> method name
  def hash_of_controllers_and_methods
    hash_of_controllers = Hash.new{ |hash, key| hash[key] = Array.new }

    list_controller_names.each do |controller|
      if controller =~ /Controller/
        cont = controller.camelize.gsub(".rb","")
        list_of_methods = (eval("#{cont}.new.methods") -
                          ApplicationController.methods -
                          Object.methods -
                          ApplicationController.new.methods)

        # remove funky meta methods (starting with _)
        list_of_methods = list_of_methods.select { |method| (method =~ /^_/).nil? }
        list_of_methods += [:manage, :read] # CanCan CRUD shortcut for all and index/show respectively
        list_of_methods.each { |method| hash_of_controllers[cont] << method }
      end
    end

    hash_of_controllers
  end


  protected

  def list_of_(type)
    return [] unless type.to_sym == :models || type.to_sym == :controllers

    target = type.to_s

    entities = Dir["app/#{target}/**/*.rb"].map do |entry|
      entry.gsub!("app/#{target}/", "")
      namespace_split = entry.split('/')
      if namespace_split.count == 2
        namespace_split[1] = namespace_split[1].capitalize
        entry = namespace_split.join('::')
      else
        entry
      end
      entry.camelize.gsub(".rb", "")
    end
    entities
  end

end
