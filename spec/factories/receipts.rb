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
