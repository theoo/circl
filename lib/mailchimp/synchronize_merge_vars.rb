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

module Mailchimp

  LOCATION_TAG = 'LOC'
  JOB_TAG = 'JOB'

  class SynchronizeMergeVars < Task

    def initialize(list_connection, logger, report)
      super(list_connection, logger, report)
    end

    def perform!
      log("starting operation -> checking existence of merge tags for location and job")
      check_existence_of_location
      check_existence_of_job
    end


    private

    def check_existence_of_location
      unless merge_vars_tags.include?(LOCATION_TAG)
        operation_result = @list_connection.list_merge_var_add(LOCATION_TAG, "location")
        log("added merge tag for location is #{operation_result}")
      end
    end

    def check_existence_of_job
      unless merge_vars_tags.include?(JOB_TAG)
        operation_result = @list_connection.list_merge_var_add(JOB_TAG, "job")
        log("added merge tag for job is #{operation_result}")
      end
    end

    def merge_vars
      @merge_vars ||= @list_connection.list_merge_vars
    end

    def merge_vars_tags
      merge_vars.map { |merge_var| merge_var['tag'] }
    end

  end

end
