require 'spec_helper'

describe Receipts::Documents do

  before :all do
    @user = FactoryGirl.create(:user)
    @generic_template = FactoryGirl.create(:generic_template)
    @subscription = FactoryGirl.create(:subscription)

    @members = []
    10.times do
      p = FactoryGirl.create(:person)
      FactoryGirl.create(:affair,
        title: @subscription.title,
        owner: p,
        buyer: p,
        receiver: p,
        value: @subscription.value_for(p),
        subscriptions: [@subscription])
      FactoryGirl.create(:invoice,
        title: @subscription.title,
        value: @subscription.value_for(p),
        invoice_template: @subscription.invoice_template_for(p),
        printed_address: p.address_for_bvr)
      @members << p
    end
  end

  def good_params
    {
      query: { search_string: "subscriptions.id:#{@subscription.id}" },
      user_id: @user.id,
      from: 10.days.ago,
      to: Time.now,
      format: "csv",
      generic_template_id: @generic_template.id
    }
  end

  it "should raise an error if params are missing" do
    required = %i(query user_id from to format generic_template_id)

    required.each do |key|
      opt = good_params
      opt.delete(key)
      expect { Receipts::Documents.perform(nil, opt) }.to raise_error(ArgumentError)
    end

  end

  it "should take people_ids array in account" do
    opt = good_params
    Receipts::Documents.perform(nil, opt)
    @members.each do |m|
      expect(m.invoices.last.title).to eq(@subscription.title)
    end
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

  it "should create a CachedDocument" do
    expect { Receipts::Documents.perform(nil, good_params) }.to change(CachedDocument, :count).by(1)
  end

  it "should send an email" do
    Receipts::Documents.perform(nil, good_params)
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(@user.email)
  end

end
