# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :activity do
  end

  factory :application_setting do
    sequence(:key)   { |n| "key #{n}" }
    sequence(:value) { |n| "value #{n}" }
  end

  factory :currency_rate do
  end

  factory :cached_document do
  end

  factory :currency do
  end

  factory :mailchimp_session do
  end

  factory :role do
    trait :admin do
      name :admin
      after(:create) do |role, evaluator|
        role.set_all_permissions!
      end
    end
  end

  factory :people_role do
  end

  factory :permission do
  end

end
