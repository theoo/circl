# == Schema Information
#
# Table name: salaries_taxes
#
#  id                 :integer          not null, primary key
#  title              :string(255)      not null
#  model              :string(255)      not null
#  created_at         :datetime
#  updated_at         :datetime
#  employee_account   :string(255)
#  exporter_avs_group :boolean          default(FALSE), not null
#  exporter_lpp_group :boolean          default(FALSE), not null
#  exporter_is_group  :boolean          default(FALSE), not null
#  employer_account   :string(255)      default("")
#  archive            :boolean          default(FALSE), not null
#

require 'spec_helper'

describe Salaries::Tax, 'validations' do

  it 'should have a title' do
    subject.should have(1).error_on(:title)
  end

  generate_length_tests_for :title, :maximum => 255

end
