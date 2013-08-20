# encoding: utf-8

require 'spec_helper'

describe Salaries::Salary do
  describe 'functional tests' do
=begin
    context 'retraite' do
      let(:salary) do
        ref = FactoryGirl.create(:reference_salary, :retraite)
        FactoryGirl.create(:salary, :reference => ref)
      end

      %w{avs ac amat is lpp}.each do |tax|
        let(tax.to_sym) { Salaries::Tax.find_by_title(tax.upcase) }
      end

      it 'taxes total should be correct' do
        salary.employee_value_total.should == 218.98.to_money
      end

      it 'net salary should be correct' do
        salary.net_salary.should == 4781.02.to_money
      end

      describe 'AVS' do
        let(:data) { salary.tax_data.where(:tax_id => avs.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == 3800.to_money
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == 3800.to_money
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 4.2
        end

        it 'employer_value should be correct' do
          data.employer_value.should == 159.6.to_money
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 4.2
        end

        it 'employee_value should be correct' do
          data.employee_value.should == 159.6.to_money
        end
      end

      describe 'AC' do
        let(:data) { salary.tax_data.where(:tax_id => ac.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == 5200.to_money
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == 5200.to_money
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 1.1
        end

        it 'employer_value should be correct' do
          data.employer_value.should == 57.2.to_money
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 1.1
        end

        it 'employee_value should be correct' do
          data.employee_value.should == 57.2.to_money
        end
      end

      describe 'AMAT' do
        let(:data) { salary.tax_data.where(:tax_id => amat.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == 5200.to_money
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == 5200.to_money
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 0.042
        end

        it 'employer_value should be correct' do
          data.employer_value.should == 2.18.to_money
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 0.042
        end

        it 'employee_value should be correct' do
          data.employee_value.should == 2.18.to_money
        end
      end
    end
=end
  end
end
