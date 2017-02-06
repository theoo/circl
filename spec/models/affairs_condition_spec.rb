# == Schema Information
#
# Table name: affairs_conditions
#
#  id          :integer          not null, primary key
#  title       :string(255)
#  description :text
#  archive     :boolean          default(FALSE), not null
#

require 'spec_helper'

describe AffairsCondition do
  pending "add some examples to (or delete) #{__FILE__}"
end
