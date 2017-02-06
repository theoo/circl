# == Schema Information
#
# Table name: receipts
#
#  id               :integer          not null, primary key
#  invoice_id       :integer
#  value_in_cents   :integer
#  value_currency   :string(255)
#  value_date       :date
#  means_of_payment :string(255)      default("")
#  created_at       :datetime
#  updated_at       :datetime
#

FactoryGirl.define do

  factory :receipt do
    invoice

    value 100
    value_date Date.today
    means_of_payment 'test'
  end

  factory :bank_import_history do
    sequence(:file_name) {|n| "File name #{n}"}
    reference_line { SecureRandom.hex }
    media_date Time.now
  end

end
