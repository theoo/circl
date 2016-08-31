FactoryGirl.define do

  factory :task do
    association :executer, factory: :person
    association :creator, factory: :person
    affair
    task_type
    # salary

    description "Temporary description"
    duration { rand(1200) }
    start_date { Time.at(rand * (Time.now.to_f - 1.month.ago.to_f) + 1.month.ago.to_f) }
  end

  factory :task_type do
    sequence(:title) { |n| "task type #{n}" }
    description "Temporary description"
    ratio { rand(2) + 1 }
    value { rand(100) + 50 }
    archive false
  end

  factory :task_rate do
    sequence(:title) { |n| "task type #{n}" }
    description "Temporary description"
    value { rand(100) + 50 }
    archive false
  end

end
