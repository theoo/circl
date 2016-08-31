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
#   required: [:source_subscriptions_id, :destination_subscriptions_id, :person]
class Subscriptions::MergeSubscriptions

  @queue = :processing

  include ResqueHelper

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("subscriptions.jobs.merge_subscriptions.title")
    set_status(translation_options: ["subscriptions.jobs.merge_subscriptions.title"])

    required = %i(source_subscription_id destination_subscription_id user_id)
    validates(params, required)

    source_subscription = Subscription.find(@source_subscription_id)
    destination_subscription = Subscription.find(@destination_subscription_id)

    # add destination subscription to all current affairs
    total = source_subscription.affairs.count
    source_subscription.affairs.each_with_index do |a, index|
      at(index + 1, total, I18n.t("common.jobs.progress", index: index + 1, total: total))
      # Append the new subscription to the current subscription's affair
    	a.subscriptions << destination_subscription
      # Change affair's title so it's easier to read
      a.update_attributes(title: destination_subscription.title)
    end

    # detach from all affairs
    source_subscription.affairs = []

    # and remove
    source_subscription.destroy

    # inform current user
    PersonMailer.send_subscriptions_merged(@user_id,
      @source_subscription_id,
      source_subscription.title,
      @destination_subscription_id).deliver

    completed(message: ["subscriptions.jobs.merge_subscriptions.an_email_have_been_sent"])

  end
end
