require 'spec_helper'

describe Salaries::Tax, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  generate_length_tests_for :title, :maximum => 255

end
