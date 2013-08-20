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

  class Synchronizer

    def self.start(logger, person_id = nil)
      report = Report.new

      current_person = Person.find person_id
      raise ArgumentError, "Unable to find person with this person_id." unless current_person

      logger.info "started mailchimp sync -> #{Time.now} for #{current_person.name} - #{current_person.email}"

      api_key   = ApplicationSetting.value('mailchimp_api_key')
      list_name = ApplicationSetting.value('mailchimp_list_name')
      connection = {
        :secure => ApplicationSetting.value('mailchimp_connection_secure') != 'false',
        :timeout => ApplicationSetting.value('mailchimp_connection_timeout').to_i
      }

      Mailchimp::Process.new(logger) do
        begin
          # get a connection this can raise a MailchimpSyncError
          list_connection = ListConnection.new(list_name, api_key, connection)

          # tasks
          DeleteUnusedEmailsOnMailchimp.new(list_connection, logger, report).perform!
          SynchronizeGroupings.new(list_connection, logger, report).perform!
          SynchronizeMergeVars.new(list_connection, logger, report).perform!
          SynchronizeEmails.new(list_connection, logger, report).perform!
        rescue MailchimpSyncError => e
          logger.fatal "MailchimpSyncError -> #{e.message}"
          report.fatal "MailchimpSyncError -> #{e.message}"
        end

        PersonMailer.send_mailchimp_sync_report(current_person, report).deliver

        logger.info "mailchimp sync finished -> #{Time.now}"
        logger.info "--------------------------------------"
      end
    end

  end

end
