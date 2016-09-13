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

# Options are:
# :person_id,
# :list_id
# :directory_query,

class BackgroundTasks::SynchronizeMailchimp < BackgroundTask
  def self.generate_title(options)
    I18n.t("background_task.tasks.synchronizing_mailchimp",
      list_id: options[:list_id])
  end

  def process!

    list_id = options[:list_id]

    # require an arel
    people = Person
      .where(id: ElasticSearch.search(options[:directory_query]).map(&:id))
      .where("people.email != ''")

    mc = MailchimpSession.new

    # Purge the current list
    result = mc.session.lists.batch_unsubscribe(list_id, mc.session.lists.members(list_id)["data"], true, false, false)

    # Resubscribe all
    subscribers = []
    people.each do |p|
      emails = [p.email]
      emails << p.second_email unless p.second_email.blank?
      emails.each do |email|
        subscribers << {
          "EMAIL" => {
            "email" => email
          },

          :merge_vars => {
            "FIRSTNAME" => p.first_name,
            "LASTNAME"  => p.last_name
          }
        }
      end
    end
    result = mc.session.lists.batch_subscribe(list_id, subscribers, false, true, false)

    # TODO send an email
    PersonMailer.send_mailchimp_sync_report(options[:person_id], list_id, result["errors"], people.count).deliver

  end
end
