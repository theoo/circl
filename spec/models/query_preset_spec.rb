require 'spec_helper'

describe QueryPreset, 'validations' do

  it 'should have a name' do
    subject.should have(1).error_on(:name)
  end

  generate_length_tests_for :name, :maximum => 255

end
