require 'spec_helper'

describe Templates::InvoiceThumbnails do

  it "should generate invoice template jpg for person" do
  	invoice_template = FactoryGirl.create(:invoice_template)
  	invoice_template.take_snapshot
  	take_snapshot1 = invoice_template.snapshot
  	GenerateInvoiceTemplateJpg.perform(invoice_template.id)
  	invoice_template.reload
  	take_snapshot2 = invoice_template.snapshot
  	expect(take_snapshot1).to eq(take_snapshot2)
  end

end
