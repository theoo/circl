require 'spec_helper'

describe GenerateDocumentAndEmail do
  
  # def self.perform(people_ids, person, from, to, format, generic_template_id, 
  # subscriptions_filter, unit_value, global_value, unit_overpaid, global_overpaid)

  before :all do
    @person = FactoryGirl.create(:person)
    
    @members = []
    10.times do 
      @members << FactoryGirl.create(:person)
    end

    @subscription = FactoryGirl.create(:subscription, members: @members)

  end

  it "should return a CachedDocument" do
  end

  it "should send an email" do
  end

  it "should take people_ids array in account" do
    # cd = call task
    # ensure cd matches expectations
  end

  it "should send to the right person" do
  end  

  it "should take interval param in account" do
  end  

  it "should take format param in account" do
  end  

  it "should use the correct template" do
  end

  it "should take subscription filter param in account" do
  end

  it "should take limits in account" do
  end

end
