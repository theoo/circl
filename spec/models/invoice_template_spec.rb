# == Schema Information
#
# Table name: invoice_templates
#
#  id                     :integer          not null, primary key
#  title                  :string(255)      default(""), not null
#  html                   :text             default(""), not null
#  created_at             :datetime
#  updated_at             :datetime
#  with_bvr               :boolean          default(FALSE)
#  bvr_address            :text             default("")
#  bvr_account            :string(255)      default("")
#  snapshot_file_name     :string(255)
#  snapshot_content_type  :string(255)
#  snapshot_file_size     :integer
#  snapshot_updated_at    :datetime
#  show_invoice_value     :boolean          default(TRUE)
#  language_id            :integer          not null
#  account_identification :string(255)
#  odt_file_name          :string(255)
#  odt_content_type       :string(255)
#  odt_file_size          :integer
#  odt_updated_at         :datetime
#

require 'spec_helper'

describe InvoiceTemplate, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  it 'should have html' do
    subject.should have(1).error_on(:html)
  end

  generate_length_tests_for :title, :bvr_account, :maximum => 255
  generate_length_tests_for :html, :bvr_address, :maximum => 65536

end
