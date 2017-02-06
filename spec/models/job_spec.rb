# == Schema Information
#
# Table name: jobs
#
#  id          :integer          not null, primary key
#  name        :string(255)      default("")
#  description :text             default("")
#

require 'spec_helper'

describe Job, 'validations' do

  it 'should have a name' do
    subject.should have(1).error_on(:name)
  end

  it 'should not have a comma in the name' do
    subject.name = "Artist, painter"
    subject.should have(1).error_on(:name)
  end

  generate_length_tests_for :name, :maximum => 255
  generate_length_tests_for :description, :maximum => 65536

end
