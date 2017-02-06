# == Schema Information
#
# Table name: receipts
#
#  id               :integer          not null, primary key
#  invoice_id       :integer
#  value_in_cents   :integer
#  value_currency   :string(255)
#  value_date       :date
#  means_of_payment :string(255)      default("")
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe Receipt, 'validations' do
  it 'should have a value' do
    subject.should have_at_least(1).error_on(:value)
  end

  it 'should have a value greater than 0' do
    subject.value = 0
    subject.should have(1).error_on(:value)
  end

  it 'should have a value_date' do
    subject.should have(1).error_on(:value_date)
  end

  generate_length_tests_for :means_of_payment, :maximum => 255
end

describe Invoice, "finance methods" do
  it "value should be a money object" do
    subject.value = 100
    subject.value.should be_instance_of Money
  end
end
