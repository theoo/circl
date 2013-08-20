require 'spec_helper'

describe Invoice, 'validations' do

  it 'should have a title' do
    subject.should have(1).errors_on(:title)
  end

  it 'should have an invoice template' do
    subject.should have(1).errors_on(:invoice_template_id)
  end

  generate_length_tests_for :title, :maximum => 255
  generate_length_tests_for :description, :printed_address, :maximum => 65536

end

describe Invoice, 'callbacks' do
  describe 'it should not be destroyable if' do
    let(:receipt) { FactoryGirl.create(:receipt) }

    it 'has a receipt' do
      expect{ receipt.invoice.destroy }.to change { Invoice.count }.by(0)
    end
  end
end

describe Invoice, "finance methods" do
  it "value should be a money object" do
    subject.value = 100
    subject.value.should be_instance_of Money
  end

  it "receipts_value should be a money object" do
    subject.receipts << FactoryGirl.create(:receipt, :value => 100)
    subject.receipts_value.should be_instance_of Money
  end

  it "balance_value should be a money object" do
    subject.value = 100
    subject.receipts << FactoryGirl.create(:receipt, :value => 100)
    subject.balance_value.should be_instance_of Money
  end

  it "overpaid_value should be a money object" do
    subject.value = 100
    subject.receipts << FactoryGirl.create(:receipt, :value => 150)
    subject.overpaid_value.should be_instance_of Money
  end
end
