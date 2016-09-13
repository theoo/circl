require 'spec_helper'

describe Subscriptions::ConcatAndEmailPdfJob, type: :job do

  before :all do
    @user = FactoryGirl.create(:user)
    # @generic_template = FactoryGirl.create(:generic_template)
    @parent_subscription = FactoryGirl.create(:subscription)
    @parent_subscription.values.each{|v| v.save!} # For an obscure reason FG doesn't save the relation

    @subscription = FactoryGirl.create(:subscription, parent_id: @parent_subscription.id)
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

    # @subscription.reload
    # @subscription.invoices.each do |invoice|
    #   FactoryGirl.create(:receipt, invoice: invoice, value: invoice.value)
    # end

    Rake::Task['elasticsearch:sync'].invoke

  end

  def good_params
    {
      query: { search_string: "subscriptions.id:#{@subscription.id}" },
      user_id: @user.id,
      subscription_id: @subscription.id,
      invoice_ids: @invoices.map(&:id),
      current_locale: @user.main_communication_language.try(:symbol)
    }
  end

  it "should raise an error if params are missing" do
    required = %i(subscription_id query invoice_ids user_id current_locale)
    required.each do |key|
      opt = good_params
      opt.delete(key)
      expect { Subscriptions::ConcatAndEmailPdf.perform(nil, opt) }.to raise_error(ArgumentError)
    end
  end

  it "should generate a pdf with the same number of page than there is invoices" do
  end

  it "page order should be invoice order" do
    # ? how to check this ?
  end

  it "should send an email to correct recipent" do
    Subscriptions::ConcatAndEmailPdf.perform(nil, good_params)
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(@user.email)
  end

end
