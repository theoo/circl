# encoding: utf-8

require 'spec_helper'

describe Salaries::Salary do
  describe 'functional tests' do
=begin
    context 'rich' do
      let(:salary) do
        ref = FactoryGirl.create(:reference_salary, :rich)
        FactoryGirl.create(:salary, :reference => ref)
      end

      %w{avs ac amat is lpp}.each do |tax|
        let(tax.to_sym) { Salaries::Tax.find_by_title(tax.upcase) }
      end
      let(:ac_solid) { Salaries::Tax.find_by_title('AC Solidarité') }

      it 'taxes total should be correct' do
        salary.employee_value_total.should == (1594.78).to_money
      end

      it 'net salary should be correct' do
        salary.net_salary.should == (13405.22).to_money
      end

      describe 'AVS' do
        let(:data) { salary.tax_data.where(:tax_id => avs.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == (15200).to_money
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == (15200).to_money
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 4.2
        end

        it 'employer_value should be correct' do
          data.employer_value.should == (638.4).to_money
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 4.2
        end

        it 'employee_value should be correct' do
          data.employee_value.should == (638.4).to_money
        end
      end

      describe 'AC' do
        let(:data) { salary.tax_data.where(:tax_id => ac.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == (15200).to_money
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == (12768).to_money
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 1.1
        end

        it 'employer_value should be correct' do
          data.employer_value.should == (140.45).to_money
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 1.1
        end

        it 'employee_value should be correct' do
          data.employee_value.should == (140.45).to_money
        end
      end

      describe 'AC Solidarité' do
        let(:data) { salary.tax_data.where(:tax_id => ac_solid.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == 15200
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == 2431.99
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 0.5
        end

        it 'employer_value should be correct' do
          data.employer_value.should == 12.16
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 0.5
        end

        it 'employee_value should be correct' do
          data.employer_value.should == 12.16
        end
      end

      describe 'AMAT' do
        let(:data) { salary.tax_data.where(:tax_id => amat.id).first }

        it 'reference_value should be correct' do
          data.reference_value.should == 15200
        end

        it 'taxed_value should be correct' do
          data.taxed_value.should == 15200
        end

        it 'employer_percent should be correct' do
          data.employer_percent.should == 0.042
        end

        it 'employer_value should be correct' do
          data.employer_value.should == 6.38
        end

        it 'employee_percent should be correct' do
          data.employee_percent.should == 0.042
        end

        it 'employee_value should be correct' do
          data.employee_value.should == 6.38
        end
      end
    end
=end
  end
end
