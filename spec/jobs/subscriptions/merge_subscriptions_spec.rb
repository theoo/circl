require 'spec_helper'

describe Subscriptions::MergeSubscriptions do

  before :all do
    @user = FactoryGirl.create(:user)
    @source_subscription = FactoryGirl.create(:subscription)
    @source_subscription.values.each{|v| v.save!} # For an obscure reason FG doesn't save the relation

    @destination_subscription = FactoryGirl.create(:subscription)
    @destination_subscription.values.each{|v| v.save!} # For an obscure reason FG doesn't save the relation

  end

  def good_params
    {
      user_id: @user.id,
      source_subscription_id: @source_subscription.id,
      destination_subscription_id: @destination_subscription.id
    }
  end

  it "should raise an error if params are missing" do
    required = %i(source_subscription_id destination_subscription_id user_id)
    required.each do |key|
      opt = good_params
      opt.delete(key)
      expect { Subscriptions::MergeSubscriptions.perform(nil, opt) }.to raise_error(ArgumentError)
    end
  end

  it "should add the destination subscription to all affairs" do

  end

  it "should remove the source subscription from all affairs" do

  end

  it "should not touch values, invoices or receipts" do

  end

  it "should not change affairs' status" do

  end

  it "should send an email to correct recipent" do
    Subscriptions::MergeSubscriptions.perform(nil, good_params)
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(@user.email)
  end

end
