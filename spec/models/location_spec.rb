require 'spec_helper'

describe Location, 'validations' do

  before(:each) do
    # FIXME use FactoryGirl
    @root = Location.create!(:name => 'earth', :postal_code_prefix => '1234')
  end

  after(:each) do
    @root.destroy
  end

  it 'validates presence of name' do
    subject.should have(1).errors_on(:name)
  end

  it 'uniqueness of name by postal_code_prefix scope' do
    Location.create!(:name => 'pipo', :postal_code_prefix => '1234', :parent => @root)
    subject.name = 'pipo'
    subject.postal_code_prefix = '1234'
    subject.parent = @root
    subject.should have(1).errors_on(:name)
  end

  it 'uniqueness of iso_codes' do
    loc = FactoryGirl.create(:location, :iso_code_a2 => "BLAH", :parent_id => 1)
    loc = FactoryGirl.create(:location, :iso_code_a3 => "BLAHH", :parent_id => 1)
    loc = FactoryGirl.create(:location, :iso_code_num => 123456, :parent_id => 1)
    subject.iso_code_a2 = "BLAH"
    subject.iso_code_a3 = "BLAHH"
    subject.iso_code_num = 123456

    subject.should have(1).errors_on(:iso_code_a2)
    subject.should have(1).errors_on(:iso_code_a3)
    subject.should have(1).errors_on(:iso_code_num)
  end

  it 'should respond to the full_name method' do
    subject.postal_code_prefix = 1234
    should respond_to(:full_name)

    subject.name = "Somewhere"
    subject.postal_code_prefix = 1234
    should respond_to(:full_name)
  end

  it 'should have a parent_id' do
    subject.should have_at_least(1).errors_on(:parent_id)
  end

  it 'should have a parent_id unless is root' do
    subject.name = @root.name
    subject.should have(0).errors_on(:parent_id)
  end

  it 'on creation it should have a valid parent_id unless is root' do
    subject.name = 'bad'
    subject.parent_id = 320010212312123
    subject.should have(1).error_on(:parent_id)
    subject.name = @root.name
    subject.should have(0).error_on(:parent_id)
  end

  generate_length_tests_for :name, :iso_code_a2, :iso_code_a3, :iso_code_num, :postal_code_prefix, :phone_prefix, :maximum => 255

end
