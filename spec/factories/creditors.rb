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
