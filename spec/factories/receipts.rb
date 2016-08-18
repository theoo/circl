FactoryGirl.define do

  factory :receipt do
    value 100
    value_date Date.today
    invoice
  end

  factory :bank_import_history do
  end

end
