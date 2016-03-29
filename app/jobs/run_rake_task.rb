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
# == Schema Information
#
# Table name: background_tasks
#
# *id*::         <tt>integer, not null, primary key</tt>
# *type*::       <tt>string(255)</tt>
# *options*::    <tt>text</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#--
# == Schema Information End
#++

# Options are: :name, :argument, :person
class RunRakeTask

  @queue = :processing

  def self.perform(arguments)
    # There's two ways of calling rake tasks with arguments
    if arguments.is_a?(Hash)
      options[:arguments].each do |k, v|
        ENV[k.to_s.upcase] = v.to_s
      end
      # Equivalent of 'rake sometask ARG1=foo ARG2=23'
      Rake::Task[options[:name]].invoke
    else
      # Equivalent of 'rake sometask[foo, 23]'
      Rake::Task[options[:name]].invoke(*options[:arguments])
    end
  end
end
