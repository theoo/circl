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

require 'rails_helper'

RSpec.describe Creditor, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
