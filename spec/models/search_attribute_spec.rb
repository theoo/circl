require 'spec_helper'

describe SearchAttribute, 'validations' do

  it 'should have a model' do
    subject.should have(1).error_on(:model)
  end

  it 'should have a name' do
    subject.should have(1).error_on(:name)
  end

  it 'should have an indexing' do
    subject.should have(1).error_on(:indexing)
  end

  generate_length_tests_for :model, :name, :group, :maximum => 255
  generate_length_tests_for :indexing, :mapping, :maximum => 65535
end
