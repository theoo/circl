require 'spec_helper'

describe Comment, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  it 'should have a description' do
    subject.should have(1).error_on(:description)
  end

  it 'should have a resource type' do
    subject.should have(2).error_on(:resource_type)
  end

  it 'should have a resource id' do
    subject.should have(1).error_on(:resource_id)
  end

  it 'should have a valid resource_type (must be a string representation of a rails model)' do
    comment = FactoryGirl.build(:comment, :resource_type => 'NotAModel')
    comment.should have(1).error_on(:resource_type)
  end

  generate_length_tests_for :title, :maximum => 255
  generate_length_tests_for :description, :maximum => 65536

end
