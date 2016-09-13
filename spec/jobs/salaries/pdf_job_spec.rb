require 'spec_helper'

describe Salaries::PdfJob, type: :job do

  it "should raise an error if params are missing" do
    expect { Salaries::Pdf.perform(nil, {}) }.to raise_error(ArgumentError)
  end

  # FIXME: Fix salary factories
  # it "should generate invoice pdf" do
  #   salary = FactoryGirl.create(:salary)
  #   expect(salary.pdf_updated_at).to be_nil
  #   Salaries::Pdf.perform(nil, salary_id: salary.id)
  #   salary.reload
  #   expect(salary.pdf_updated_at).to be_instance_of ActiveSupport::TimeWithZone
  #   expect(salary.pdf_updated_at).to be > Time.now - 1.second
  # end

end
