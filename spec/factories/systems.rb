FactoryGirl.define do

  app_models = Module.constants.select do |constant_name|
    constant = eval(constant_name.to_s)
    if not constant.nil? and constant.is_a? Class and constant.superclass == ActiveRecord::Base
      constant
    end
  end

  factory :activity do
  end

  factory :application_setting do
    sequence(:key)   { |n| "key #{n}" }
    sequence(:value) { |n| "value #{n}" }
    type_for_validation { %w(time boolean integer float string url email).sample }
  end

  factory :cached_document do
    validity_time 86400
    # document # Paperclip
  end

  factory :currency do
    sequence(:priority) {|n| n }
    iso_code { rand(100..1000).to_s }
    iso_numeric { rand(100).to_s }
    sequence(:name) {|n| "currency #{n}" }
    symbol { rand(100..1000).to_s }
    subunit "cent"
    subunit_to_unit 100
    separator "'"
    delimiter "."
  end

  factory :currency_rate do
    association :from_currency, factory: :currency
    association :to_currency, factory: :currency
    rate { rand(2) }
  end

  factory :mailchimp_session do
  end

  factory :role do
    sequence(:name) {|n| "role #{n} - #{SecureRandom.hex}" }

    trait :admin do
      name :admin
      after(:create) do |role, evaluator|
        role.set_all_permissions!
      end
    end
  end

  factory :people_role do
    person
    role
  end

  factory :permission do
    role

    action "manage"
    subject app_models.sample
    hash_conditions nil
  end

end
