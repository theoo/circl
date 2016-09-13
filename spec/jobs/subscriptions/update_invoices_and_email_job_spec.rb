require 'spec_helper'

describe Subscriptions::UpdateInvoicesAndEmailJob, type: :job do

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
      user_id: @user.id,
      subscription_id: @subscription.id,
    }
  end

  it "should raise an error if params are missing" do
    required = %i(subscription_id user_id)
    required.each do |key|
      opt = good_params
      opt.delete(key)
      expect { Subscriptions::UpdateInvoicesAndEmail.perform(nil, opt) }.to raise_error(ArgumentError)
    end
  end

  it "should update all invoice and affair titles" do

  end

  it "should update all invoice and value titles" do
    # Try to reach complicated corner cases where the model could possibly prevent the invoice update (paid?).
  end

  it "should send an email to correct recipent" do
    Subscriptions::UpdateInvoicesAndEmail.perform(nil, good_params)
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(@user.email)
  end

end
