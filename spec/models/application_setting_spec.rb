require 'spec_helper'

describe ApplicationSetting, 'validations' do

  after(:each) { ApplicationSetting.destroy_all }

  it 'should have a key' do
    subject.should have(1).error_on(:key)
  end

  it 'should have a value' do
    subject.should have(1).error_on(:value)
  end

  it 'should have a unique key' do
    setting_1 = FactoryGirl.create(:application_setting, :key => 'key')
    setting_2 = FactoryGirl.build(:application_setting, :key => 'key')
    setting_2.should have(1).error_on(:key)
  end

  it 'should not be possible to change the key' do
    setting = FactoryGirl.create(:application_setting)
    setting.key += 'changed'
    setting.should have(1).error_on(:key)
  end

  generate_length_tests_for :key, :maximum => 255
  generate_length_tests_for :value, :maximum => 255

end
