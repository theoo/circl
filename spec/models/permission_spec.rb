# == Schema Information
#
# Table name: permissions
#
#  id              :integer          not null, primary key
#  role_id         :integer
#  action          :string(255)      default("")
#  subject         :string(255)      default("")
#  hash_conditions :text
#  created_at      :datetime
#  updated_at      :datetime
#

require 'spec_helper'

describe Permission, 'validations' do

  it 'should have an action' do
    subject.should have(1).error_on(:action)
  end

  it 'should have a subject' do
    subject.should have(1).error_on(:subject)
  end

  it 'should have a role_id' do
    subject.should have(1).error_on(:role_id)
  end

  generate_length_tests_for :action, :subject, :maximum => 255

end
