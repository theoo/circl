class CachedDocument < ApplicationRecord

  has_attached_file :document, use_timestamp: true

  do_not_validate_attachment_file_type :document
  # validates_attachment :document,
  #   presence: true,
  #   content_type: { content_type: /\A.*\Z/ },
  #   size: { in: 0..100.megabytes }

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
