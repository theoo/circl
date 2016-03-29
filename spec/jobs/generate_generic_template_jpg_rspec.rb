require 'spec_helper'

describe GenerateGenericTemplateJpg do
  it "should generate generic template jpg for person" do
  	generic_template = FactoryGirl.create(:generic_template, :class => GenericTemplate)
  	generic_template.take_snapshot
  	take_snapshot1 = generic_template.snapshot
  	GenerateGenericTemplateJpg.perform(generic_template.id)
  	generic_template.reload
  	take_snapshot2 = generic_template.snapshot
  	expect(take_snapshot1).to eq(take_snapshot2)
  end
end
