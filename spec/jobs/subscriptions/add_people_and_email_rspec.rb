require 'spec_helper'

describe Subscriptions::AddPeopleAndEmail do

	before :all do
      @p1 = FactoryGirl.create(:person, :email => "test1@circl.ch")
      @a1 = @p1.affairs.create!(:title => "affair1#{@p1.id}")
      @s1 = @p1.affairs.first.subscriptions.create!(:title => "subscription1#{@p1.id}")

    @members = []
    10.times do 
      @person = FactoryGirl.create(:person)
      @members << @person
    end
  end

  it "should add people ans send email" do
  	Subscriptions::AddPeopleAndEmail.perform(@s1.id, @members, @p1, nil, nil)
  end

end
