FactoryGirl.define do

  factory :subscription do
    # parent_id

    sequence(:title) { |n| "subscription #{n} - #{SecureRandom.hex}" }
    description "Temporary description"
    # interval_starts_on
    # interval_ends_on
    # pdf # Paperclip
    # last_pdf_generation_query

    after(:create) do |sub, evaluator|
      # sub.values << FactoryGirl.create(:subscription_value, subscription: sub)
      create_list(:subscription_value, 1, subscription: sub)
    end

  end

  factory :subscription_value do
    invoice_template
    private_tag

    value { rand(100) }
    sequence(:position) {|n| n}
  end

end
