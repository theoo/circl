# == Schema Information
#
# Table name: products
#
#  id                 :integer          not null, primary key
#  provider_id        :integer
#  after_sale_id      :integer
#  key                :string(255)      not null
#  title              :string(255)
#  category           :string(255)
#  description        :text
#  has_accessories    :boolean          default(FALSE), not null
#  archive            :boolean          default(FALSE), not null
#  created_at         :datetime
#  updated_at         :datetime
#  unit_symbol        :string(255)
#  price_to_unit_rate :integer
#  width              :integer
#  height             :integer
#  depth              :integer
#  volume             :integer
#  weight             :integer
#

require 'spec_helper'

describe Product do
  pending "add some examples to (or delete) #{__FILE__}"
end
