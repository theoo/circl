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

require 'hominid'

module Mailchimp
  class SynchronizeGroupings < Task

    # TODO:
    # should be 60 but api call refuses more than around 30
    # try to load 60 interest groups in batch?
    MAX_ITEMS_IN_GROUPING = 30

    # TODO: move this elsewhere
    # dependency on Mailchimp::PersonConverter
    RAILS_GROUPINGS = [{:grouping_name  => 'main communication language',
                        :groups => Language.all.map(&:name),
                        :person_attribute => 'main_communication_language' },

                       {:grouping_name  => 'communication languages',
                        :groups => Language.all.map(&:name),
                        :person_attribute => 'communication_languages' },

                       {:grouping_name  => 'roles',
                        :groups => Role.all.map(&:name),
                        :person_attribute => 'roles' },

                       {:grouping_name  => 'private_tags',
                        :groups => PrivateTag.all.map(&:name),
                        :person_attribute => 'private_tags' },

                       {:grouping_name  => 'public_tags',
                        :groups => PublicTag.all.map(&:name),
                        :person_attribute => 'public_tags' }]

    def initialize(list_connection, logger, report)
      super(list_connection, logger, report)
    end

    def perform!
      log "starting operation -> delete and re-upload groupings"
      delete_all_groupings_on_mailchimp
      add_interest_groupings_from_db
    end

    private

    def delete_all_groupings_on_mailchimp
      groupings.each do |grouping|
        # operation_result is a bool
        operation_result = @list_connection.list_interest_grouping_del(grouping['id'])
        log("delete grouping '#{grouping['name']}' is #{operation_result}")
      end
    end

    def add_interest_groupings_from_db
      RAILS_GROUPINGS.each do |rails_grouping|
        groups = cleanup_groups(rails_grouping[:grouping_name], rails_grouping[:groups])
        @list_connection.list_interest_grouping_add(rails_grouping[:grouping_name], 'hidden', groups )

        log("added grouping #{rails_grouping[:grouping_name]}")
      end
    end

    def groupings
      @groupings ||= @list_connection.list_interest_groupings
    end

    def cleanup_groups(grouping_name, groups)
      if groups.uniq.size > MAX_ITEMS_IN_GROUPING
        log("grouping #{grouping_name} has too many items. #{groups.uniq.size - MAX_ITEMS_IN_GROUPING} are ignored")
        log("warning: the missing groups will not be on the mailchimp list")
        groups.uniq.slice(0, MAX_ITEMS_IN_GROUPING)
      else
        groups.uniq
      end
    end

  end
end
