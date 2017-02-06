=begin

require 'spec_helper'

describe Task, 'validations' do

  it 'should have a date' do
    subject.should have(1).error_on(:date)
  end

  it 'date should not be in the future' do
    subject.date = Date.today + 1.hour
    subject.should have(1).error_on(:date)
  end

  it 'should have a duration' do
    subject.should have(1).error_on(:duration)
  end

  it 'duration should be positive' do
    subject.duration = -5
    subject.should have(1).error_on(:duration)
  end

  it 'should have a description' do
    subject.should have(1).error_on(:description)
  end

  generate_length_tests_for :description, :maximum => 65536

end

describe Task, 'relationship attributes' do
  it 'should belongs to a person' do
    pending "check it's an integer"
    subject.should have(1).error_on(:person_id)
  end
end

=end
