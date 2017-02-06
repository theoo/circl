# == Schema Information
#
# Table name: affairs
#
#  id              :integer          not null, primary key
#  owner_id        :integer          not null
#  buyer_id        :integer          not null
#  receiver_id     :integer          not null
#  title           :string(255)      default(""), not null
#  description     :text             default("")
#  value_in_cents  :integer          default(0), not null
#  value_currency  :string(255)      default("CHF"), not null
#  created_at      :datetime
#  updated_at      :datetime
#  status          :integer          default(0), not null
#  estimate        :boolean          default(FALSE), not null
#  parent_id       :integer
#  footer          :text
#  conditions      :text
#  seller_id       :integer          default(1), not null
#  condition_id    :integer
#  unbillable      :boolean          default(FALSE), not null
#  notes           :text
#  vat_percentage  :float
#  vat_in_cents    :integer          default(0), not null
#  vat_currency    :string(255)      default("CHF"), not null
#  alias_name      :string(255)
#  execution_notes :text
#  archive         :boolean          default(FALSE), not null
#  sold_at         :datetime
#

require 'spec_helper'

describe Affair, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  it 'should have an owner' do
    subject.should have(1).error_on(:owner_id)
  end

  it 'should have a buyer' do
    subject.should have(1).error_on(:buyer_id)
  end

  it 'should have a receiver' do
    subject.should have(1).error_on(:receiver_id)
  end

  generate_length_tests_for :title, :maximum => 255
  generate_length_tests_for :description, :maximum => 65536

end
