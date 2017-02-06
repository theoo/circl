# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)      default("")
#  description :text             default("")
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

# FIXME use FactoryGirl

describe Role, "validations" do

  it 'should have a name' do
    subject.should have(1).error_on(:name)
  end

  it 'should have a unique name' do
    subject.name = 'admin'
    subject.save
    other_role = Role.new(:name => 'admin')
    other_role.should have(1).error_on(:name)
  end

  generate_length_tests_for :name, :maximum => 255
  generate_length_tests_for :description, :maximum => 65536

end

describe Role, "callbacks" do
  it 'should not be deletable if it belongs to a person' do
    subject.name = "admin"
    subject.people << stub_model(Person, :id => 0)
    subject.save

    expect{
      subject.destroy
    }.to change { Role.count }.by(0)
  end

  it 'should destroy related permissions' do
    subject.name = "admin"
    permission = stub_model(Permission, :id => 0, :path => 'RolesController#create')
    subject.permissions << permission
    subject.save

    permission.should_receive(:destroy)
    subject.destroy
  end
end
