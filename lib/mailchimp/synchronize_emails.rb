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

  class SynchronizeEmails < Task
    # A person may have a lot of associated information, better to set a small BATCH_SIZE here
    BATCH_SIZE = 5

    def initialize(list_connection, logger, report)
      super(list_connection, logger, report)
      @operation_result = {}
    end

    def perform!
      log "starting operation -> updating users"
      first_id_after_god = 2
      # TODO: change find_in_batches so it can exclude a set of ids. (God's ids)
      Person.find_in_batches(:batch_size => BATCH_SIZE, :start => first_id_after_god) do |person_batch|
        person_batch = person_batch.reject { |p| p.email.blank? }
        update_batch(person_batch)
      end
      log(@operation_result)
    end

    private

    def update_batch(person_batch)
      mailchimp_batch = convert_to_mailchimp_format(person_batch)
      current_operation_result = @list_connection.subscribe(mailchimp_batch)
      @operation_result = @operation_result.merge(current_operation_result) { |key, old_val, new_val| old_val + new_val }
    end

    def convert_to_mailchimp_format(person_batch)
      person_batch.map { |person| PersonConverter.new(person, @logger, @report, groupings_on_mailchimp).convert }
    end

    # this was on PersonConverter
    # moved here to avoid an api call per user ...
    def groupings_on_mailchimp
      @groupings_on_mailchimp ||= @list_connection.list_interest_groupings
    end
  end
end
