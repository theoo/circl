# encoding: utf-8

FactoryGirl.define do
  # factory :employment_contract do
  #   trait :current do
  #     interval_starts_on Date.today
  #   end

  #   trait :old do
  #     interval_starts_on Date.today - 3.month
  #   end

  #   interval_ends_on { interval_starts_on + 1.month }

  #   percentage 50
  #   person
  # end

  factory :person do
    sequence(:email) { |n| "test-#{SecureRandom.hex}@test.com" }
    trait :admin do
      email 'admin@circl.ch'
      roles { [ FactoryGirl.create(:role, :admin) ] }
    end
  end

end
