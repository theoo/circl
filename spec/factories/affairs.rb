# encoding: utf-8

FactoryGirl.define do

  ### Basic Pupets
  factory :affair do
    sequence(:title) { |n| "affair #{n}" }
    association :owner, :factory => :person
    association :buyer, :factory => :person
    association :receiver, :factory => :person
  end

  factory :affairs_condition do
    sequence(:title) { |n| "condition #{n}" }
    description "Temporary description"
    archive false
  end

  # TODO rename affairs_products_category in affair_products_category everywhere
  factory :affairs_products_category do
    affair
    sequence(:title) { |n| "category #{n}" }
    sequence(:position) { |n| n }
  end

  # TODO rename affairs_stakeholder in affair_stakeholder everywhere
  factory :affairs_stakeholder do
    person
    affair
    sequence(:title) { |n| "stakeholder #{n}" }
  end

  # TODO rename affairs_subscription in affair_subscription everywhere
  factory :affairs_subscription do
    affair
    subscription
  end

  factory :extra do
    affair
    sequence(:title) { |n| "extra #{n}" }
    description "Temporary description"
    value { rand(1000) }
    quantity { rand(10) }
    sequence(:position) { |n| n }
  end

  ### Extended Pupets

end
