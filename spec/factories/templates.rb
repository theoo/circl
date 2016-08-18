# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :generic_template do
  end

  factory :invoice_template do
    sequence(:title) { |n| "invoice template #{n}" }
    sequence(:html)  { |n| "html #{n}" }
    language
  end

end
