# encoding: utf-8

FactoryGirl.define do
  factory :employment_contract do
    trait :current do
      interval_starts_on Date.today
    end

    trait :old do
      interval_starts_on Date.today - 3.month
    end

    interval_ends_on { interval_starts_on + 1.month }

    percentage 50
    person
  end

  factory :comment do
    sequence(:title)       { |n| "comment #{n}" }
    sequence(:description) { |n| "description #{n}" }

    association :resource, :factory => :person
    person
  end

  factory :person do
    sequence(:email) { |n| "test-#{n}@test.com" }
    trait :admin do
      email 'admin@circl.ch'
      roles { [ FactoryGirl.create(:role, :admin) ] }
    end
  end

  factory :role do
    trait :admin do
      name :admin
      after(:create) do |role, evaluator|
        role.set_all_permissions!
      end
    end
  end

  factory :application_setting do
    sequence(:key)   { |n| "key #{n}" }
    sequence(:value) { |n| "value #{n}" }
  end

  factory :language do
    sequence(:name) { |n| "language #{n}" }
  end

  factory :location do
    sequence(:name) { |n| "location #{n}" }

    trait :root do
      name 'earth'
    end
  end
end
