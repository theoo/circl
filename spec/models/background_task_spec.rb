require 'spec_helper'

describe BackgroundTask, 'validations' do

  it 'should not be schedulable twice' do
    invoice = FactoryGirl.create(:invoice)
    BackgroundTasks::GenerateInvoicePdf.schedule(:invoice_id => invoice.id).should be_true
    BackgroundTasks::GenerateInvoicePdf.schedule(:invoice_id => invoice.id).should be_false
  end

end
