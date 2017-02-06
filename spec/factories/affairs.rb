# encoding: utf-8
# == Schema Information
#
# Table name: affairs
#
#  id              :integer          not null, primary key
#  owner_id        :integer          not null
#  buyer_id        :integer          not null
#  receiver_id     :integer          not null
#  title           :string(255)      default(""), not null
#  description     :text             default("")
#  value_in_cents  :integer          default(0), not null
#  value_currency  :string(255)      default("CHF"), not null
#  created_at      :datetime
#  updated_at      :datetime
#  status          :integer          default(0), not null
#  estimate        :boolean          default(FALSE), not null
#  parent_id       :integer
#  footer          :text
#  conditions      :text
#  seller_id       :integer          default(1), not null
#  condition_id    :integer
#  unbillable      :boolean          default(FALSE), not null
#  notes           :text
#  vat_percentage  :float
#  vat_in_cents    :integer          default(0), not null
#  vat_currency    :string(255)      default("CHF"), not null
#  alias_name      :string(255)
#  execution_notes :text
#  archive         :boolean          default(FALSE), not null
#  sold_at         :datetime
#


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
