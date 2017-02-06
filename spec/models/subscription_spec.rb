# == Schema Information
#
# Table name: subscriptions
#
#  id                        :integer          not null, primary key
#  title                     :string(255)      default(""), not null
#  description               :text             default("")
#  interval_starts_on        :date
#  interval_ends_on          :date
#  created_at                :datetime
#  updated_at                :datetime
#  pdf_file_name             :string(255)
#  pdf_content_type          :string(255)
#  pdf_file_size             :integer
#  pdf_updated_at            :datetime
#  last_pdf_generation_query :text
#  parent_id                 :integer
#

require 'spec_helper'

describe Subscription, 'validations' do

  it 'should have a name' do
    subject.should have(1).error_on(:title)
  end

  it 'should have a unique name' do
    subscription1 = FactoryGirl.create(:subscription)
    subscription2 = FactoryGirl.build(:subscription, :title => subscription1.title)
    subject.should have(1).error_on(:title)
  end

  it 'its interval_starts_on should not be in the past of interval_ends_on' do
    subject.interval_ends_on = Time.now
    subject.interval_starts_on = Time.now + 1.day
    subject.should have(1).error_on(:interval_ends_on)
  end

  generate_length_tests_for :title, :maximum => 255
  generate_length_tests_for :description, :maximum => 65536

end

describe Subscription, "callbacks" do
  describe "should not be deletable if" do
    it 'it has receipts' do
      receipt = FactoryGirl.create(:receipt)
      expect{ receipt.affair.subscriptions.first.destroy }.to change{Subscription.count}.by(0)
    end

    it "it has children" do
      child = FactoryGirl.create(:subscription, :title => "lplop")
      subject.title = "Grrr"
      subject.children << child
      expect { subject.destroy }.to_not change(Subscription, :count)

      subject.errors.include?(:base).should == true # works
    end
  end
end

describe Subscription, "finance methods" do
  it "invoices_value should be a money object" do
    subject.invoices << FactoryGirl.create(:invoice, :value => 100)
    subject.invoices_value.should be_instance_of Money
  end

  it "receipts_value should be a money object" do
    subject.invoices << FactoryGirl.create(:invoice, :value => 100)
    subject.invoices.first.receipts << FactoryGirl.create(:receipt, :value => 100)
    subject.receipts_value.should be_instance_of Money
  end

  it "balance_value should be a money object" do
    subject.invoices << FactoryGirl.create(:invoice, :value => 100)
    subject.invoices.first.receipts << FactoryGirl.create(:receipt, :value => 200)
    subject.balance_value.should be_instance_of Money
  end

  it "overpaid_value should be a money object" do
    subject.invoices << FactoryGirl.create(:invoice, :value => 100)
    subject.invoices.first.receipts << FactoryGirl.create(:receipt, :value => 200)
    subject.overpaid_value.should be_instance_of Money
  end
end

describe Subscription, "tree" do

  describe "tree_level method" do
    it "should return an Fixnum" do
      subject.tree_level.should be_instance_of Fixnum
    end
    it "should return level 0 for root" do
      subject.tree_level.should == 0
    end

    it "should should return 3 for a fourth level child" do
      root   = FactoryGirl.create(:subscription)
      second = FactoryGirl.create(:subscription)
      third  = FactoryGirl.create(:subscription)
      subject.parent = third
      third.parent  = second
      second.parent = root

      subject.tree_level.should == 3
    end
  end

  %w(receipts_from_self_and_descendants invoices_from_self_and_descendants).each do |method|
    describe "#{method} method" do
      it "should return an array" do
        subject.send(method).should be_instance_of Array
      end

      it "should return one dimention array" do
        subject.send(method).each do |member|
          member.should_not be_instance_of Array
        end
      end
    end
  end

  it "people_from_self_and_descendants should return an AREL object" do
    subject.people_from_self_and_descendants.should be_instance_of ActiveRecord::Relation
  end

  describe "relationship methods" do
    before(:each) do |i|
      @it1 = FactoryGirl.create(:invoice_template)

      @p1 = FactoryGirl.create(:person, :email => "test#{i.object_id + 1}@circl.ch")
      @a1 = @p1.affairs.create!(:title => "affair1#{@p1.id}")
      @s1 = @p1.affairs.first.subscriptions.create!(:title => "subscription1#{@p1.id}")
      @i1 = @a1.invoices.create!(:title => "invoice1#{@p1.id}", :value => 50, :invoice_template_id => @it1.id)
      @r1 = @i1.receipts.create!(:value => 50, :value_date => Time.now)

      @p2 = FactoryGirl.create(:person, :email => "test#{i.object_id + 2}@circl.ch")
      @a2 = @p2.affairs.create!(:title => "affair2#{@p2.id}")
      @s2 = @p2.affairs.first.subscriptions.create!(:title => "subscription2#{@p2.id}", :parent => @s1)
      @i2 = @a2.invoices.create!(:title => "invoice2#{@p2.id}", :value => 50, :invoice_template_id => @it1.id)
      @r2 = @i2.receipts.create!(:value => 50, :value_date => Time.now)

      # the last subscription should not be part of the result
      @p3 = FactoryGirl.create(:person, :email => "test#{i.object_id + 3}@circl.ch")
      @a3 = @p3.affairs.create!(:title => "affair3#{@p3.id}")
      @s3 = @p3.affairs.first.subscriptions.create!(:title => "subscription3#{@p3.id}")
      @i3 = @a3.invoices.create!(:title => "invoice3#{@p3.id}", :value => 100, :invoice_template_id => @it1.id)
      @r3 = @i3.receipts.create!(:value => 50, :value_date => Time.now)
    end

    it "people_from_self_and_descendants should contain people from self and its children" do
      @s1.reload
      @s1.people_from_self_and_descendants.size.should == 2
      @s1.people_from_self_and_descendants.should include @p1
      @s1.people_from_self_and_descendants.should include @p2
      @s1.people_from_self_and_descendants.should_not include @p3
    end

    it "invoices_from_self_and_descendants should return the right invoices" do
      @s1.reload
      @s3.reload

      @s1.invoices_from_self_and_descendants.size.should == 2
      @s1.invoices_from_self_and_descendants.should include @i1
      @s1.invoices_from_self_and_descendants.should include @i2
      @s1.invoices_from_self_and_descendants.should_not include @i3
      @s3.invoices_from_self_and_descendants.should include @i3
    end

    it "get_people_from_affairs_status(:paid) should return an array" do
      subject.get_people_from_affairs_status(:paid).should be_instance_of Array
    end

    it "should contain person from self and its children" do
      @s1.reload
      @s1.get_people_from_affairs_status(:paid).should include(@p1)
      @s1.get_people_from_affairs_status(:paid).should include(@p2)
      @s1.get_people_from_affairs_status(:paid).should_not include(@p3)
    end
  end
end

describe Subscription, 'values' do

  before(:all) do
    subject.title = "testing"
    subject.save
  end

  after(:all) do
    subject.destroy
  end

  it "should return an array of SubscriptionValue object" do
    subject.values.should be_instance_of Array

    subject.values do |v|
      v.should be_instance_of SubscriptionValue
    end
  end

  it "should have at least on value" do
    subject.values.size.should > 0
  end

  it "should have a catchall value (*)" do
    subject.values.where(:private_tag_id => nil).count.should > 0
  end

  it "value_for method should return a Money object" do
    p = FactoryGirl.create(:person)
    subject.value_for(p).should be_instance_of Money
  end

  it "invoice_template_for method should return a InvoiceTemplate object" do
    p = FactoryGirl.create(:person)
    subject.invoice_template_for(p).should be_instance_of InvoiceTemplate
  end

end
