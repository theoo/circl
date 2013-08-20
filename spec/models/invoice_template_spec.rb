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
