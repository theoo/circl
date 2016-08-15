require 'spec_helper'

describe Subscriptions::UpdateInvoicesAndEmail do
	before :all do
      @p1 = FactoryGirl.create(:person, :email => "test1@circl.ch")
      @a1 = @p1.affairs.create!(:title => "affair1#{@p1.id}")
      @s1 = @p1.affairs.first.subscriptions.create!(:title => "subscription1#{@p1.id}")
  end
  it "update invoice and send email" do
  	Subscriptions::UpdateInvoicesAndEmail.perform(@s1.id, @p1)
  end
end
