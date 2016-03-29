require 'spec_helper'

describe GenerateGenericTemplateJpg do
  it "should generate generic template jpg for person" do
  	generic_template = FactoryGirl.create(:generic_template, :class => GenericTemplate)
  	take_snapshot1 = generic_template.take_snapshot
  	take_snapshot2 = GenerateGenericTemplateJpg.perform(generic_template.id)
  	expect(take_snapshot1).to eq(take_snapshot2)
  end
end
