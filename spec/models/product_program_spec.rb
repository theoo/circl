# == Schema Information
#
# Table name: product_programs
#
#  id            :integer          not null, primary key
#  key           :string(255)      not null
#  program_group :string(255)      not null
#  title         :string(255)
#  description   :text
#  archive       :boolean          default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe ProductProgram do
  pending "add some examples to (or delete) #{__FILE__}"
end
