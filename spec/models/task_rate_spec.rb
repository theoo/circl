# == Schema Information
#
# Table name: task_rates
#
#  id             :integer          not null, primary key
#  title          :string(255)      not null
#  description    :text
#  value_in_cents :integer          not null
#  value_currency :string(255)      default("CHF")
#  archive        :boolean          default(FALSE)
#  created_at     :datetime
#  updated_at     :datetime
#

require 'spec_helper'

describe TaskRate do
  pending "add some examples to (or delete) #{__FILE__}"
end
