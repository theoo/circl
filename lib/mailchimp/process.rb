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

  LOCK_FILE = File.join(Rails.root.to_s, 'tmp', 'mailchimp_sync_process.lock')

  class Process
    def initialize(logger)
      @logger = logger

      if process_running?
        @logger.warn("Mailchimp Synchronization already started")
        @logger.warn("stopping further operations")
        return
      end

      if block_given?
        lock_job
        begin
          yield
        rescue => e
          @logger.warn("mailchimp process failed raised error -> #{e.message}")
          @logger.warn("mailchimp process backtrace -> #{e.backtrace}")
        ensure
          unlock_job
        end
      end
    end


    private

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
end
