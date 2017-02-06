# == Schema Information
#
# Table name: product_variants
#
#  id                     :integer          not null, primary key
#  product_id             :integer          not null
#  program_group          :string(255)      not null
#  title                  :string(255)
#  buying_price_in_cents  :integer
#  buying_price_currency  :string(255)      default("CHF"), not null
#  selling_price_in_cents :integer          not null
#  selling_price_currency :string(255)      default("CHF")
#  art_in_cents           :integer
#  art_currency           :string(255)      default("CHF")
#  created_at             :datetime
#  updated_at             :datetime
#  vat_in_cents           :integer          default(0), not null
#  vat_currency           :string(255)      default("CHF"), not null
#  vat_percentage         :integer
#

require 'spec_helper'

describe ProductVariant do
  pending "add some examples to (or delete) #{__FILE__}"
end
