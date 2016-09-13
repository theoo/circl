require 'spec_helper'

describe Invoices::PdfJob, type: :job do

  it "should raise an error if params are missing" do
    expect { Invoices::Pdf.perform(nil, {}) }.to raise_error(ArgumentError)
  end

  it "should generate invoice pdf" do
    invoice = FactoryGirl.create(:invoice)
    expect(invoice.pdf_updated_at).to be_nil
    Invoices::Pdf.perform(nil, invoice_id: invoice.id)
    invoice.reload
    expect(invoice.pdf_updated_at).to be_instance_of ActiveSupport::TimeWithZone
    expect(invoice.pdf_updated_at).to be > Time.now - 1.second
  end

end
