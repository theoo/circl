# == Schema Information
#
# Table name: currency_rates
#
#  id               :integer          not null, primary key
#  from_currency_id :integer          not null
#  to_currency_id   :integer          not null
#  rate             :float            not null
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe CurrencyRate do
  pending "add some examples to (or delete) #{__FILE__}"
end
