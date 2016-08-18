# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :invoice do
    sequence(:title) { |n| "invoice #{n}" }
    value 100
    affair
    invoice_template
  end

end
