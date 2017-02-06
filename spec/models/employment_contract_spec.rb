# == Schema Information
#
# Table name: employment_contracts
#
#  id                 :integer          not null, primary key
#  person_id          :integer
#  percentage         :float
#  interval_starts_on :date
#  interval_ends_on   :date
#  description        :text             default("")
#  created_at         :datetime
#  updated_at         :datetime
#

require 'spec_helper'

describe EmploymentContract, 'validations' do

  it 'should have a percentage' do
    subject.should have(2).error_on(:percentage)
  end

  it 'should only accept integers on percentage' do
    pending
    # subject.percentage = 10.5
    # subject.should have(1).error_on(:percentage)
  end

  it 'should have a valid percentage (1-100)' do
    subject.percentage = 400
    subject.should have(1).error_on(:percentage)
  end

  it 'should validate presence of interval_starts_on' do
    subject.should have(1).error_on(:interval_starts_on)
  end

  it 'should validate presence of interval_ends_on' do
    subject.should have(1).error_on(:interval_ends_on)
  end

  it 'should have a valid interval (start must come before end in time) ' do
    start_date = Date.new(2011, 1, 1)
    end_date = start_date - 10

    subject.interval_starts_on = start_date
    subject.interval_ends_on = end_date

    subject.should have(1).error_on(:interval_ends_on)
  end

  it 'should always have a person on creation' do
    subject.should have(1).error_on(:person_id)
  end

  it 'should always belongs to an existing person' do
    subject.person_id = 0 # should not be a valid id in db
    subject.should have(1).error_on(:person_id)
  end

  generate_length_tests_for :description, :maximum => 65536

end

describe EmploymentContract, 'callback' do

  after(:each) { EmploymentContract.destroy_all }

  describe 'it should not be destroyable if' do
    it 'the interval is still current' do
      employment_contract = FactoryGirl.create(:employment_contract, :current)
      expect{ employment_contract.destroy }.to change{ EmploymentContract.count }.by(0)
    end
  end

  describe 'it should be destroyable if' do
    it 'the interval is in the future or the past' do
      employment_contract = FactoryGirl.create(:employment_contract, :old)
      expect{ employment_contract.destroy }.to change{ EmploymentContract.count }.by(-1)
    end
  end

end

describe EmploymentContract, "is_running" do
  it 'should be false if interval is in the past' do
    subject.interval_starts_on = Date.new(2011, 1, 1)
    subject.interval_ends_on = Date.new(2011, 1, 10)

    today = Date.new(2011, 1, 20)
    Date.stub(:today => today)

    subject.is_running?.should == false
  end

  it 'should be false if interval is in the future' do
    subject.interval_starts_on = Date.new(2011, 2, 1)
    subject.interval_ends_on = Date.new(2011, 2, 10)

    today = Date.new(2011, 1, 20)
    Date.stub(:today => today)

    subject.is_running?.should == false
  end

  it 'should be true if today is both after interval_start and before interval_end' do
    subject.interval_starts_on = Date.new(2011, 1, 1)
    subject.interval_ends_on = Date.new(2011, 1, 10)

    today = Date.new(2011, 1, 5)
    Date.stub(:today => today)

    subject.is_running?.should == true
  end

  it 'should be true if today == interval_starts_on' do
    subject.interval_starts_on = Date.new(2011, 1, 1)
    subject.interval_ends_on = Date.new(2011, 1, 10)

    today = Date.new(2011, 1, 1)
    Date.stub(:today => today)

    subject.is_running?.should == true
  end

  it 'should be true if today == interval_ends_on' do
    subject.interval_starts_on = Date.new(2011, 1, 1)
    subject.interval_ends_on = Date.new(2011, 1, 10)

    today = Date.new(2011, 1, 10)
    Date.stub(:today => today)

    subject.is_running?.should == true
  end
end
