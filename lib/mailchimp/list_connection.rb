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

require 'hominid'


# an interest grouping is a group of tags
# an interest group is an individual group
# i.e. an interest grouping can have many interest groups

module Mailchimp

  class ListConnection

    def initialize(list_name, api_key, connection_configuration)
      attempt_connection(list_name, api_key, connection_configuration)
    end

    def list_members(status, start, limit)
      since = ""
      ApiFilter.new { @hominid.list_members(@list_id, status, since, start, limit) }.call
    end

    def remove_subscribers(emails)
      list_batch_unsubscribe(emails, true, false, false)
    end

    def list_batch_unsubscribe(emails, delete_member, send_goodbye, send_notify)
      ApiFilter.new { @hominid.list_batch_unsubscribe(@list_id, emails, delete_member, send_goodbye, send_notify) }.call
    end

    def subscribe(batch)
      double_opt_in = false
      update_existing = true
      replace_interests = true

      ApiFilter.new { @hominid.list_batch_subscribe(@list_id, batch, double_opt_in, update_existing, replace_interests) }.call
    end

    # special case
    # raises an error when there are no groupings, we want [] instead
    def list_interest_groupings
      begin
        @hominid.list_interest_groupings(@list_id)
      rescue Hominid::APIError => e
        []
      end
    end

    def list_interest_grouping_del(grouping_id)
      ApiFilter.new { @hominid.list_interest_grouping_del(grouping_id) }.call
    end

    def list_interest_grouping_add(name, type, groups)
      ApiFilter.new { @hominid.list_interest_grouping_add(@list_id, name, type, groups) }.call
    end

    def list_merge_vars
      ApiFilter.new { @hominid.list_merge_vars(@list_id) }.call
    end

    def list_merge_var_add(tag, full_name)
      ApiFilter.new { @hominid.list_merge_var_add(@list_id, tag, full_name) }.call
    end


    private

    def attempt_connection(list_name, api_key, connection_configuration)
      @hominid = ApiFilter.new { Hominid::API.new(api_key, connection_configuration) }.call

      @list = ApiFilter.new { @hominid.find_list_by_name(list_name) }.call
      if @list.nil?
        raise MailchimpSyncError, "list '#{list_name}' not found on mailchimp servers"
      else
        @list_id = @list['id']
      end
    end

  end

  class GroupingNotFoundError < StandardError
  end
end
