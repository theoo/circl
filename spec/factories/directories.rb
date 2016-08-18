FactoryGirl.define do

  factory :comment do
    sequence(:title)       { |n| "comment #{n}" }
    sequence(:description) { |n| "description #{n}" }

    association :resource, :factory => :person
    person
  end

  factory :job do
  end

  factory :language do
    sequence(:name) { |n| "language #{n}" }
  end

  factory :ldap_attribute do
  end

  factory :location do
    sequence(:name) { |n| "location #{n}" }

    trait :root do
      name 'earth'
    end
  end

  factory :people_communication_language do
  end

  factory :people_private_tag do
  end

  factory :people_public_tag do
  end

  factory :private_tag do
  end

  factory :public_tag do
  end

  factory :query_preset do
  end

  factory :search_attribute do
  end

end
