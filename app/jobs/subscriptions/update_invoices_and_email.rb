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
# == Schema Information
#
# Table name: background_tasks
#
# *id*::         <tt>integer, not null, primary key</tt>
# *type*::       <tt>string(255)</tt>
# *options*::    <tt>text</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#--
# == Schema Information End
#++

# Options are: subscription_id, :person
class Subscriptions::UpdateInvoicesAndEmail
  
  @queue = :notifications

  def self.perform(subscription_id, person)
    subscription = Subscription.find(subscription_id)

    # A rake task is runned in a closed context, doing this doesn't disable
    # elasticsearch for the entire app.
    Rails.configuration.settings['elasticsearch']['enable_index'] = false

    subscription.update_invoices!
    subscription.update_affairs!

    Rails.configuration.settings['elasticsearch']['enable_index'] = true

    subscription.people.each{|p| p.update_index}

    PersonMailer.send_subscription_invoices_updated(person,
                                                    subscription.id).deliver
  end
end
