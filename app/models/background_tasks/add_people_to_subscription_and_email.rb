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

# Options are: subscriptions_id, :person, :people_ids
class BackgroundTasks::AddPeopleToSubscriptionAndEmail < BackgroundTask

  def self.generate_title(options)
    I18n.t("background_task.tasks.add_people_to_subscription_and_email",
      :people_count => options[:people_ids].size,
      :subscription_id => options[:subscription_id],
      :subscription_title => Subscription.find(options[:subscription_id]).title)
  end

  def process!
    subscription = Subscription.find(options[:subscription_id])

    existing_people_ids = []
    new_people_ids = []
    options[:people_ids].each do |id|
      p = Person.find(id)
      if p.subscriptions.include?(subscription)
        existing_people_ids << p.id
        next
      end

      a = p.affairs.create!(:title => subscription.title,
                            :owner => p,
                            :buyer => p,
                            :receiver => p,
                            :value => subscription.value_for(p),
                            :subscriptions => [subscription])
      a.invoices.create!(:title => subscription.title,
                         :value => subscription.value_for(p),
                         :invoice_template => subscription.invoice_template_for(p),
                         :printed_address => p.address_for_bvr )

      new_people_ids << p.id
    end

    PersonMailer.send_members_added_to_subscription(options[:person],
                  subscription.id,
                  new_people_ids,
                  existing_people_ids).deliver
  end
end
