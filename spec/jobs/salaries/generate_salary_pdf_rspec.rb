require 'spec_helper'

describe Salaries::GenerateSalaryPdf do
  it "should generate salaries pdf" do
  	salary = FactoryGirl.create(:salary, :class => Salaries::Salary)
  	generator = AttachmentGenerator.new(salary)
  	generator_pdf = generator.update_attributes pdf: generator.pdf
  	Salaries::GenerateSalaryPdf.perform(salary.id)
  	expect(ES.search(generator).pdf).be eq(generator_pdf)
  end
end
