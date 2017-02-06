# == Schema Information
#
# Table name: creditors
#
#  id                   :integer          not null, primary key
#  creditor_id          :integer
#  affair_id            :integer
#  title                :string(255)
#  description          :text
#  value_in_cents       :integer          default(0), not null
#  value_currency       :string(255)      default("CHF"), not null
#  vat_in_cents         :integer          default(0), not null
#  vat_currency         :string(255)      default("CHF"), not null
#  vat_percentage       :string(255)
#  invoice_received_on  :date
#  invoice_ends_on      :date
#  invoice_in_books_on  :date
#  discount_percentage  :float            default(0.0)
#  discount_ends_on     :date
#  paid_on              :date
#  payment_in_books_on  :date
#  account              :string(255)
#  transitional_account :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  discount_account     :string(255)
#  vat_account          :string(255)
#  vat_discount_account :string(255)
#

FactoryGirl.define do

  ### Basic Pupets
  factory :creditor do
    association :creditor, factory: :person
    # affair
    sequence(:title) { |n| "credit #{n}" }
    description "Temporary description"
    value { rand(1000) }
    invoice_received_on 1.day.ago
    invoice_ends_on 1.month.since
    invoice_in_books_on 1.weeks.since
    discount_percentage 10
    discount_ends_on 2.weeks.since
    paid_on 1.week.since
    payment_in_books_on 6.weeks.since
    sequence(:account) { |n| SecureRandom.hex }
    sequence(:transitional_account) { |n| SecureRandom.hex }
    sequence(:discount_account) { |n| SecureRandom.hex }
    sequence(:vat_account) { |n| SecureRandom.hex }
    sequence(:vat_discount_account) { |n| SecureRandom.hex }
  end

  ### Extended Pupets

end
