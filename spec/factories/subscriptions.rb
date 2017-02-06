# == Schema Information
#
# Table name: subscriptions
#
#  id                        :integer          not null, primary key
#  title                     :string(255)      default(""), not null
#  description               :text             default("")
#  interval_starts_on        :date
#  interval_ends_on          :date
#  created_at                :datetime
#  updated_at                :datetime
#  pdf_file_name             :string(255)
#  pdf_content_type          :string(255)
#  pdf_file_size             :integer
#  pdf_updated_at            :datetime
#  last_pdf_generation_query :text
#  parent_id                 :integer
#

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
