# == Schema Information
#
# Table name: tasks
#
#  id             :integer          not null, primary key
#  executer_id    :integer          not null
#  description    :text             default("")
#  duration       :integer
#  created_at     :datetime
#  updated_at     :datetime
#  affair_id      :integer          not null
#  task_type_id   :integer          not null
#  value_in_cents :integer          default(0), not null
#  value_currency :string(255)      default("CHF"), not null
#  salary_id      :integer
#  start_date     :datetime
#  creator_id     :integer
#

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
