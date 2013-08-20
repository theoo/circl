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
