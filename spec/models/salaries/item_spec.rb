require 'spec_helper'

describe Salaries::Item, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  it 'value should return a Money object' do
    subject.value.should be_instance_of Money
  end

  generate_length_tests_for :title, :maximum => 255

end
