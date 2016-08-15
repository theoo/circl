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

class Subscriptions::UpdateInvoicesAndEmail

  @queue = :processing

  include ResqueHelper

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("subscriptions.background_tasks.update_invoices_and_email.title")
    set_status(translation_options: ["subscriptions.background_tasks.update_invoices_and_email.title"])

    required = %i(subscription_id user_id)
    validates(params, required)

    subscription = Subscription.find(@subscription_id)

    # A rake task is runned in a closed context, doing this doesn't disable
    # elasticsearch for the entire app.
    Rails.configuration.settings['elasticsearch']['enable_index'] = false

    subscription.update_invoices!
    subscription.update_affairs!

    Rails.configuration.settings['elasticsearch']['enable_index'] = true

    total = subscription.people.count
    subscription.people.each_with_index do |p, index|
      at(index + 1, total, I18n.t("backgroun_tasks.progress", index: index + 1, total: total))
      p.update_index
    end

    PersonMailer.send_subscription_invoices_updated(@user_id, @subscription_id).deliver

    completed(message: ["subscriptions.background_tasks.update_invoices_and_email.an_email_have_been_sent"])

  end
end
