require 'spec_helper'

describe SubscriptionValue, 'validations' do

  it "should belongs to a subscription" do
    subject.should have(2).error_on(:subscription_id)
    subject.errors[:subscription_id].should include(I18n.t 'activerecord.errors.messages.empty')
    subject.errors[:subscription_id].should include(I18n.t 'activerecord.errors.messages.not_a_number')
  end

  it "should belongs to an invoice_template" do
    subject.should have(2).error_on(:invoice_template_id)
    subject.errors[:invoice_template_id].should include(I18n.t 'activerecord.errors.messages.empty')
    subject.errors[:invoice_template_id].should include(I18n.t 'activerecord.errors.messages.not_a_number')
  end

  it "should have a value" do
    subject.value_in_cents = nil
    subject.value_currency = nil
    subject.save

    subject.should have(2).error_on(:value_in_cents)
    subject.errors[:value_in_cents].should include(I18n.t 'activerecord.errors.messages.empty')
    subject.errors[:value_in_cents].should include(I18n.t 'activerecord.errors.messages.not_a_number')
    subject.should have(1).error_on(:value_currency)
    subject.errors[:value_currency].should include(I18n.t 'activerecord.errors.messages.empty')
  end

  it "value should return a Money object" do
    subject.value.should be_instance_of Money
  end

  it "should have a position" do
    subject.save
    subject.position.should >= 0
  end

end
