require 'spec_helper'

describe Subscriptions::PreparePdfsAndEmail do
	before :all do
      @p1 = FactoryGirl.create(:person, :email => "test1@circl.ch")
      @a1 = @p1.affairs.create!(:title => "affair1#{@p1.id}")
      @s1 = @p1.affairs.first.subscriptions.create!(:title => "subscription1#{@p1.id}")

    @members = []
    10.times do 
      @person = FactoryGirl.create(:person)
      @affair = @person.affairs.create(:title => "affair test")
      @invoice = @affair.invoices.create!(:value => 100, :title => 'transfer invoice', :invoice_template_id => 1)
      @receipt = @invoice.receipts.create!(:value => 200, :value_date => Time.now)
      @members << @person
    end
  end
  it "prepare pdfs and send email" do
  	#This test should cover the Subscriptions::ConcatAndEmailPdf, GenerateInvoicePdf and Subscriptions::PreparePdfsAndEmail jobs.
  	Subscriptions::PreparePdfsAndEmail.perform(@s1.id, @members, @p1, nil, I18n.locale)
  end
end
