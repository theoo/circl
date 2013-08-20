require 'spec_helper'

describe Admin::SubscriptionsController do

  login_admin

  describe "basic tests" do

    it "index returns the list of subscriptions" do
      subscription = FactoryGirl.create(:subscription)
      get :index
      expect{assigns(:subscriptions).to include(subscription)}
    end

    describe "show action" do
      it "should return subscription as json" do
        pending
      end

      it "should return invoices as PDF" do
        pending
      end
    end


    it "add_members effectively adds members" do
      pending
    end

    it "remove_members effectively removes members" do
      pending
    end

    it "create effectively creates a subscription" do
      pending
    end

    describe "update action" do
      it "should record changes" do
        pending
      end

      it "should update depending invoices(invoice_template, value) and affairs(values)" do
        pending
      end
    end

    it "search works for autocompleters" do
      pending
    end

    describe "tag_tool tags correctly people who" do
      it "are member of a paid subscription for which its interval include today" do
        pending
      end

      it "are not member of a paid subscription for which its interval include today" do
        pending
      end

      it "are member of a unpaid subscription for which its interval include today" do
        pending
      end
    end
  end

  describe "transfer overpaid value" do
    before(:each) do
      @person = Person.create!(:email => "plop@plop.com")
      @affair = @person.affairs.create(:title => "affair test")
      @affair.subscriptions = [Subscription.create!(:title => 'transfert sub', :invoice_template_id => 1)]
      @invoice = @affair.invoices.create!(:value => 100, :title => 'transfer invoice', :invoice_template_id => 1)
      @receipt = @invoice.receipts.create!(:value => 200, :value_date => Time.now)

      @subscription = @affair.subscriptions.first
      @destination = Subscription.create!(:title => 'transfert test', :invoice_template_id => 1)
    end

    it "should return status 200 if parameters are correct" do
      put :transfer_overpaid_value, :id => @subscription.id, :transfer_to_subscription_id => @destination.id
      expect{ response.status.to eq(200)}
    end

    it "for one receipt" do
      pending "require more advance skills to write this test"
      @subscription.invoices_value.should == (@subscription.receipts_value - 100.to_money)
      @destination.invoices_value.should == 0
      @destination.receipts_value.should == 0

      put :transfer_overpaid_value, :id => @subscription.id, :transfer_to_subscription_id => @destination.id

      @subscription.reload
      @destination.reload

      @subscription.invoices_value.should == 100.to_money
      @subscription.invoices_value.should == @subscription.receipts_value
      @destination.invoices_value.should == 100.to_money
      @destination.receipts_value.should == @destination.invoices_value
    end

    it "for multiple receipt" do
      pending "require more advance skills to write this test"
      invoice = FactoryGirl.create(:invoice, :value => 100)
      FactoryGirl.create(:receipt, :value => 50, :invoice => invoice)
      FactoryGirl.create(:receipt, :value => 60, :invoice => invoice)
      FactoryGirl.create(:receipt, :value => 20, :invoice => invoice)
      FactoryGirl.create(:receipt, :value => 50, :invoice => invoice)
      FactoryGirl.create(:receipt, :value => 20, :invoice => invoice)

      from = invoice.affair.subscriptions.first
      to   = FactoryGirl.create(:subscription)

      from.invoices_value.should == (from.receipts_value - 100.to_money)
      to.invoices_value.should == 0.to_money
      to.receipts_value.should == 0.to_money

      expect {
        put :transfer_overpaid_value, :id => from.id, :transfer_to_subscription_id => to.id
      }.to change{ invoice.receipts.count }.from(5).to(2)

      from.reload
      to.reload

      from.invoices_value.should == from.receipts_value
      from.invoices_value.should == 100.to_money
      to.invoices_value.should == to.receipts_value
      to.receipts_value.should == 100.to_money
    end

  end

end
