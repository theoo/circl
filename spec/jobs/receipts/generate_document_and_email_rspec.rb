require 'spec_helper'

describe Receipts::GenerateDocumentAndEmail do

  # def self.perform(people_ids, person, from, to, format, generic_template_id,
  # subscriptions_filter, unit_value, global_value, unit_overpaid, global_overpaid)

  before :all do
    @person1 = FactoryGirl.create(:person)

    @members = []
    10.times do
      @person = FactoryGirl.create(:person)
      @affair = @person.affairs.create(:title => "affair test")
      @invoice = @affair.invoices.create!(:value => 100, :title => 'transfer invoice', :invoice_template_id => 1)
      @receipt = @invoice.receipts.create!(:value => 200, :value_date => Time.now)
      @members << @person
    end
  end

  it "should return a CachedDocument" do
    expect {Receipts::GenerateDocumentAndEmail.perform(@members, @person1, nil, nil, 'pdf', 1, nil, nil, nil, nil, nil)}.to change(CachedDocument, :count).by(1)
  end

  it "should send an email" do
    #Need smtp settings to send emails.
  end

  it "should take people_ids array in account" do
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
