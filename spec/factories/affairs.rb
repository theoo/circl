# encoding: utf-8

FactoryGirl.define do
  factory :affair do
    sequence(:title) { |n| "affair #{n}" }
    association :owner, :factory => :person
    association :buyer, :factory => :person
    association :receiver, :factory => :person
    subscriptions { [FactoryGirl.create(:subscription)] }
  end

  factory :invoice do
    sequence(:title) { |n| "invoice #{n}" }
    value 100
    affair
    invoice_template
  end

  factory :receipt do
    value 100
    value_date Date.today
    invoice
  end

  factory :subscription do
    sequence(:title) { |n| "subscription #{n}" }
  end

  factory :subscription_value do
    invoice_template
    value 100
    position 0
  end

  factory :invoice_template do
    sequence(:title) { |n| "invoice template #{n}" }
    sequence(:html)  { |n| "html #{n}" }
    language
  end
end
