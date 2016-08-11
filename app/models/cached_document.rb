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

class CachedDocument < ActiveRecord::Base

  has_attached_file :document, use_timestamp: true

  validates_attachment_content_type :document, :content_type => /\A.*\Z/ # Disable validation

  # TODO Private ApplicationSetting for duration value
  scope :outdated_documents, -> { where("created_at < ?", 1.day.ago) }

  before_save do
    self.validity_time = 1.day.seconds
  end

  # Class methods
  class << self

    def erase_outdated_documents
      outdated_documents.destroy_all
    end

  end

  # Instance methods
  def public_url
    Rails.configuration.settings["directory_url"] + document.url
  end

end
