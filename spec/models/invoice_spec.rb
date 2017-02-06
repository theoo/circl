# == Schema Information
#
# Table name: invoices
#
#  id                  :integer          not null, primary key
#  title               :string(255)      default("")
#  description         :text             default("")
#  value_in_cents      :integer          not null
#  value_currency      :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  affair_id           :integer
#  printed_address     :text             default("")
#  invoice_template_id :integer          not null
#  pdf_file_name       :string(255)
#  pdf_content_type    :string(255)
#  pdf_file_size       :integer
#  pdf_updated_at      :datetime
#  status              :integer          default(0), not null
#  cancelled           :boolean          default(FALSE), not null
#  offered             :boolean          default(FALSE), not null
#  vat_in_cents        :integer          default(0), not null
#  vat_currency        :string(255)      default("CHF"), not null
#  vat_percentage      :float
#  conditions          :text
#  condition_id        :integer
#

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
