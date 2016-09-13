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

# Options are: :name, :argument, :person
class RunRakeTaskJob < ApplicationJob

  queue_as :processing
  include ResqueHelper

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("admin.jobs.run_rake_task.title")
    set_status(translation_options: ["admin.jobs.run_rake_task.title"])

    # There's two ways of calling rake tasks with arguments
    if options.is_a?(Hash)
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
