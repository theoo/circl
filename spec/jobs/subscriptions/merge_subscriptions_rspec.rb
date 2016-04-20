require 'spec_helper'

describe Subscriptions::MergeSubscriptions do
	before :all do
      @p1 = FactoryGirl.create(:person, :email => "test1@circl.ch")
      @a1 = @p1.affairs.create!(:title => "affair1#{@p1.id}")
      @s1 = @p1.affairs.first.subscriptions.create!(:title => "subscription1#{@p1.id}")
      @s2 = @p1.affairs.first.subscriptions.create!(:title => "subscription2#{@p1.id}")
  end

  it "should merge subscriptions" do
  	Subscriptions::MergeSubscriptions.perform(@s1.id, @s2.id, @p1)
  end

end
