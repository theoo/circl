# == Schema Information
#
# Table name: invoices
#
#  id                  :integer          not null, primary key
#  title               :string(255)      default("")
#  description         :text             default("")
#  value_in_cents      :integer          not null
#  value_currency      :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  affair_id           :integer
#  printed_address     :text             default("")
#  invoice_template_id :integer          not null
#  pdf_file_name       :string(255)
#  pdf_content_type    :string(255)
#  pdf_file_size       :integer
#  pdf_updated_at      :datetime
#  status              :integer          default(0), not null
#  cancelled           :boolean          default(FALSE), not null
#  offered             :boolean          default(FALSE), not null
#  vat_in_cents        :integer          default(0), not null
#  vat_currency        :string(255)      default("CHF"), not null
#  vat_percentage      :float
#  conditions          :text
#  condition_id        :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :invoice do
    sequence(:title) { |n| "invoice #{n}" }
    value 100
    affair
    invoice_template
  end

end
