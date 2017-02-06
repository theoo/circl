# == Schema Information
#
# Table name: cached_documents
#
#  id                    :integer          not null, primary key
#  validity_time         :integer
#  created_at            :datetime
#  updated_at            :datetime
#  document_file_name    :string(255)
#  document_content_type :string(255)
#  document_file_size    :integer
#  document_updated_at   :datetime
#

require 'spec_helper'

describe CachedDocument do
  pending "add some examples to (or delete) #{__FILE__}"
end
