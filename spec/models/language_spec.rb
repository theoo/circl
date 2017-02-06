# == Schema Information
#
# Table name: languages
#
#  id   :integer          not null, primary key
#  name :string(255)      default("")
#  code :string(255)      default("")
#

require 'spec_helper'

describe Language, 'validations' do

  it 'should have a name' do
  	subject.name = nil
    subject.should have(1).error_on(:name)
  end

  it 'name should be unique' do
    language1 = FactoryGirl.create(:language)
    language2 = FactoryGirl.build(:language, :name => language1.name)
    language2.should have(1).error_on(:name)
  end

  generate_length_tests_for :name, :code, :maximum => 255

end
