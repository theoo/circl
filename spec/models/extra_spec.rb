# == Schema Information
#
# Table name: extras
#
#  id             :integer          not null, primary key
#  affair_id      :integer
#  title          :string(255)
#  description    :text
#  value_in_cents :integer
#  value_currency :string(255)
#  quantity       :float
#  position       :integer
#  created_at     :datetime
#  updated_at     :datetime
#  vat_in_cents   :integer          default(0), not null
#  vat_currency   :string(255)      default("CHF"), not null
#  vat_percentage :float
#

require 'spec_helper'

describe Extra do
  pending "add some examples to (or delete) #{__FILE__}"
end
