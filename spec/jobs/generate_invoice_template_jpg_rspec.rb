require 'spec_helper'

describe GenerateInvoiceTemplateJpg do
  it "should generate invoice template jpg for person" do
  	invoice_template = FactoryGirl.create(:invoice_template)
  	take_snapshot1 = invoice_template.take_snapshot
  	take_snapshot2 = GenerateInvoiceTemplateJpg.perform(invoice_template.id)
  	expect(take_snapshot1).to eq(take_snapshot2)
  end
end
