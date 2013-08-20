require 'spec_helper'

describe Activity, 'validations' do

  it 'should have a resource type' do
    subject.should have(2).error_on(:resource_type)
  end

  it 'should have a resource id' do
    subject.should have(1).error_on(:resource_id)
  end

  it 'should have an action' do
    subject.should have(1).error_on(:action)
  end

  it 'should have data' do
    subject.should have(1).error_on(:data)
  end

  it 'should have a valid resource_type (must be a string representation of a rails model)' do
    activity = Activity.new(:resource_id => 34, :resource_type => 'NotAModelName')
    activity.should have(1).error_on(:resource_type)
  end

  generate_length_tests_for :action, :maximum => 255

end
