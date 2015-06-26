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

# Options are: :people_ids, :person
class BackgroundTasks::SynchronizeMailchimp < BackgroundTask
  def self.generate_title(options)
    I18n.t("background_task.tasks.synchronizing_mailchimp",
      people_count: options[:people_ids].size)
 end

  def process!
    # TODO error catching
    # TODO report
    people_ids = options[:people_ids]
    list_id = options[:list_id]

    errors = {private_tags: [], public_tags: [], people: []}

    people = Person.where(id: people_ids).where("people.email != ''")
    people_emails = people.pluck(:email, :second_email)
    people_emails.delete("")

    mc = MailchimpAccount.new
    session = mc.session

    # Add missing segments
    [:private_tags, :public_tags].each do |tag_class|
      mc_segments = mc.segments(list_id)

      klass = tag_class.to_s.classify.constantize
      tags = klass.joins(:people).where("people.id" => people_ids).where("people.email != ''")
      tags.each do |tag|
        begin
          # add if new
          mc_segments.merge( session.lists.static_segment_add(list_id, tag.name) ) unless mc_segments[tag.name]
        rescue Mailchimp::ListInvalidOptionError => e
          errors[tag_class][tag.name] = e.inspect
        end

        # add members to tag
        mc_segments.each_pair do |name, id|
          emails = tag.people.where(id: people_ids).where("people.email != ''").pluck(:email, :second_email)
          session.lists.static_segment_members_add(list_id, id, emails)
        end
      end
    end

    raise ArgumentError, errors.inspect

    # Add missing groups

    # Add missing emails

    # Link emails and segements

    # Link emails and groups

  end
end
