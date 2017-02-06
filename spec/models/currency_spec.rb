# == Schema Information
#
# Table name: currencies
#
#  id              :integer          not null, primary key
#  priority        :integer
#  iso_code        :string(255)      not null
#  iso_numeric     :string(255)
#  name            :string(255)
#  symbol          :string(255)
#  subunit         :string(255)
#  subunit_to_unit :integer
#  separator       :string(255)
#  delimiter       :string(255)
#

require 'spec_helper'

describe Currency do
  pending "add some examples to (or delete) #{__FILE__}"
  describe "validations" do
    it "should not be possible to delete a currency currently used by any model" do
      pending
    end
  end
end
