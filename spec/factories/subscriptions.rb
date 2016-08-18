# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :subscription do
    sequence(:title) { |n| "subscription #{n}" }
  end

  factory :subscription_value do
    invoice_template
    value 100
    position 0
  end

end
