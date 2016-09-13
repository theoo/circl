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

class Synchronize::MailchimpJob < ApplicationJob

  queue_as :sync

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("admin.jobs.mailchimp.title")
    set_status(translation_options: ["admin.jobs.mailchimp.title"])

    required = %i(user_id list_id query)
    validates(params, required)

    people_ids = ElasticSearch.search(
      @query[:search_string],
      @query[:selected_attributes],
      @query[:attributes_order])
      .map(&:id)

    # require an arel
    people = Person
      .where(id: people_ids)
      .where("people.email != ''")

    mc = MailchimpSession.new

    # Purge the current list
    result = mc.session.lists.batch_unsubscribe(list_id, mc.session.lists.members(list_id)["data"], true, false, false)

    # Resubscribe all
    # TODO sync second email (and all if more)
    subscribers = people.map do |p|
      {
        "EMAIL" => {
          "email" => p.email
        },

        :merge_vars => {
          "FIRSTNAME" => p.first_name,
          "LASTNAME"  => p.last_name
        }
      }
    end
    result = mc.session.lists.batch_subscribe(@list_id, subscribers, false, true, false)

    PersonMailer.send_mailchimp_sync_report(@user_id, @list_id, result["errors"], people.count).deliver

    completed(message: ["admin.jobs.mailchimp.completed"])

  end
end
