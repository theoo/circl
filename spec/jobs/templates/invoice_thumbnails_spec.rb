require 'spec_helper'

describe Templates::InvoiceThumbnails do

  before :all do
    @template = FactoryGirl.create(:invoice_template)
  end

  it "should generate a thumbnail for the given template" do
    # FIXME paperclip default_url doesn't work in this case. Newly created template doesn't have an odt attached.
    expect(@template.snapshot_updated_at).to be_nil
    Templates::InvoiceThumbnails.perform(nil, ids: @template.id)
    @template.reload
    expect(@template.snapshot_updated_at).to be_instance_of ActiveSupport::TimeWithZone
    expect(@template.snapshot_updated_at).to be > 2.seconds.ago
  end

end
