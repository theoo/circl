# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :creditor do
    creditor_id 1
    affair_id 1
    title "MyString"
    description "MyText"
    value_in_cents 1
    value_currency "MyString"
    vat_in_cents 1
    vat_currency "MyString"
    invoice_received_on "2015-07-20"
    invoice_end_on "2015-07-20"
    invoice_in_books_on "2015-07-20"
    discount_percentage 1.5
    paid_on "2015-07-20"
    payment_in_books_on "2015-07-20"
  end
end
