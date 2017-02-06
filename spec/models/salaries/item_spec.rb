# == Schema Information
#
# Table name: salaries_items
#
#  id             :integer          not null, primary key
#  parent_id      :integer
#  salary_id      :integer          not null
#  position       :integer          not null
#  title          :string(255)      not null
#  value_in_cents :integer          not null
#  category       :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  value_currency :string(255)      default("CHF"), not null
#

require 'spec_helper'

describe Salaries::Item, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  it 'value should return a Money object' do
    subject.value.should be_instance_of Money
  end

  generate_length_tests_for :title, :maximum => 255

end
