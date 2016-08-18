# encoding: utf-8

FactoryGirl.define do

  factory :affair do
    sequence(:title) { |n| "affair #{n}" }
    association :owner, :factory => :person
    association :buyer, :factory => :person
    association :receiver, :factory => :person
    # subscriptions { [FactoryGirl.create(:subscription)] }
  end

  factory :affairs_conditions do
  end

  # TODO rename affairs_products_category in affair_products_category everywhere
  factory :affairs_products_category do
  end

  # TODO rename affairs_stakeholder in affair_stakeholder everywhere
  factory :affairs_stakeholder do
  end

  # TODO rename affairs_subscription in affair_subscription everywhere
  factory :affairs_subscription do
  end

  factory :extra do
  end

end
