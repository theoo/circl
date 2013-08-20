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
  class DeleteUnusedEmailsOnMailchimp < Task

    BATCH_SIZE = 10

    def initialize(list_connection, logger, report)
      super(list_connection, logger, report)

      # TODO: move this in super class
      @operation_result = {}
    end

    def perform!
      emails_to_remove = emails_on_mailchimp - emails_in_db
      unless emails_to_remove.empty?
        log("starting operation -> delete unused emails on mailchimp")
        batches = emails_to_remove.each_slice(BATCH_SIZE).to_a

        batches.each do |batch|
          current_operation_result = @list_connection.remove_subscribers(batch)
          @operation_result = @operation_result.merge(current_operation_result) { |key, old_val, new_val| old_val + new_val }
        end

        log("attempted to remove #{emails_to_remove.size} emails, succesfully removed #{@operation_result['success_count']}")
        log(@operation_result)
      end

    end

    private

    def emails_in_db
      Person.all.map(&:email).reject(&:blank?).map(&:downcase)
    end

    def emails_on_mailchimp
      # starting page
      start = 0
      # num of elements
      limit = 5000
      status = 'subscribed'
      all_emails = []

      while true
        a_page_of_members = @list_connection.list_members("subscribed", start, limit)
        emails = a_page_of_members['data'].map { |record| record['email'] }
        break if emails.empty?
        all_emails.concat(emails)
        start += 1
      end
      all_emails.map(&:downcase)
    end

  end
end
