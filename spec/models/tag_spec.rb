require 'spec_helper'

[PrivateTag, PublicTag].each do |tag|
  describe tag, 'validations' do

    it 'should have a name' do
      subject.should have(1).error_on(:name)
    end

    generate_length_tests_for :name, :maximum => 255

  end
end
