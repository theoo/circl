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

require 'mailchimp'

class MailchimpAccount

  LOCK_FILE = File.join(Rails.root.to_s, 'tmp', 'mailchimp_sync_process.lock')

  attr_accessor :session

  def initialize()
    @api_key = ApplicationSetting.value(:mailchimp_api_key)
    @session = Mailchimp::API.new(@api_key)
  end

  def lists
    h = {}
    @session.lists.list['data'].map{|l| h[l['name']] = l['id']}
    h
  end

  def segments(list_id)
    h = {}
    @session.lists.segments(list_id, 'static')['static'].map{|s| h[s['name']] = s['id']}
    h
  end

  def process_running?
    File.file? LOCK_FILE
  end

  def lock_job
    FileUtils.touch(LOCK_FILE)
  end

  def unlock_job
    FileUtils.rm(LOCK_FILE) if process_running?
  end

end