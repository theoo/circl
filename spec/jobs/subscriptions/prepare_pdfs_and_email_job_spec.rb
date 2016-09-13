require 'spec_helper'

describe Subscriptions::PreparePdfsAndEmailJob, type: :job do
  before :all do
    @user = FactoryGirl.create(:user)

    @subscription = FactoryGirl.create(:subscription)
    @subscription.values.each{|v| v.save!} # For an obscure reason FG doesn't save the relation

    @invoices = []
    @members = []
    10.times do
      p = FactoryGirl.create(:person)
      # NOTE I could use add_people_and_email job instead...
      FactoryGirl.create(:affair,
        title: @subscription.title,
        owner: p,
        buyer: p,
        receiver: p,
        value: @subscription.value_for(p),
        subscriptions: [@subscription])
      invoice = FactoryGirl.create(:invoice,
        title: @subscription.title,
        value: @subscription.value_for(p),
        invoice_template: @subscription.invoice_template_for(p),
        printed_address: p.address_for_bvr)
      @members << p
      @invoices << invoice
    end

  end

  def good_params
    {
      query: { search_string: "subscriptions.id:#{@subscription.id}" },
      user_id: @user.id,
      subscription_id: @subscription.id,
      current_locale: @user.main_communication_language.try(:symbol)
    }
  end

  it "should raise an error if params are missing" do
    required = %i(subscription_id query user_id current_locale)
    required.each do |key|
      opt = good_params
      opt.delete(key)
      expect { Subscriptions::PreparePdfsAndEmail.perform(nil, opt) }.to raise_error(ArgumentError)
    end
  end

  it "should generate and invoice for each person in the given subscription" do

  end

  it "should trigger ConcatAndEmail job at the end" do

  end

end
