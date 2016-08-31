require 'spec_helper'

describe Subscriptions::AddPeopleAndEmail do

  before :all do
    @user = FactoryGirl.create(:user)
    # @generic_template = FactoryGirl.create(:generic_template)
    @parent_subscription = FactoryGirl.create(:subscription)
    @parent_subscription.values.each{|v| v.save!} # For an obscure reason FG doesn't save the relation

    @subscription = FactoryGirl.create(:subscription, parent_id: @parent_subscription.id)
    @subscription.values.each{|v| v.save!} # For an obscure reason FG doesn't save the relation

    # @subscription.invoices.each do |invoice|
    #   FactoryGirl.create(:receipt, invoice: invoice, value: invoice.value)
    # end

    # @members = []
    # 10.times do
    #   p = FactoryGirl.create(:person)
    #   FactoryGirl.create(:affair,
    #     title: @subscription.title,
    #     owner: p,
    #     buyer: p,
    #     receiver: p,
    #     value: @subscription.value_for(p),
    #     subscriptions: [@subscription])
    #   FactoryGirl.create(:invoice,
    #     title: @subscription.title,
    #     value: @subscription.value_for(p),
    #     invoice_template: @subscription.invoice_template_for(p),
    #     printed_address: p.address_for_bvr)
    #   @members << p
    # end

    # Rake::Task['elasticsearch:sync'].invoke

  end

  def good_params
    {
      query: { search_string: "subscriptions.id:#{@subscription.id}" },
      user_id: @user.id,
      subscription_id: @subscription.id,
      parent_subscription_id: @parent_subscription.id,
      status: 'renewal'
    }
  end

  it "should raise an error if params are missing" do
    required = %i(query subscription_id user_id parent_subscription_id status)
    required.each do |key|
      opt = good_params
      opt.delete(key)
      expect { Subscriptions::AddPeopleAndEmail.perform(nil, opt) }.to raise_error(ArgumentError)
    end
  end

  it "should add people corresponding to the search engine query" do
  end

  it "should copy information from parent subscription if subscription_parent is provided" do
    # like owner/buyer/receiver
  end

  it "should create an affair an invoice for each member of the subscription" do
  end

  it "should send an email to correct recipent" do
    Subscriptions::AddPeopleAndEmail.perform(nil, good_params)
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(@user.email)
  end

end
