# encoding: utf-8

require 'spec_helper'

describe Salaries::Salary do
  describe 'functional tests' do
# TODO Almost working, but the testing stack is too messy
#    context 'french' do
#      let(:salary) do
#        ref = FactoryGirl.create(:reference_salary, :french)
#        FactoryGirl.create(:salary, :reference => ref)
#      end
#
#      %w{avs ac amat is lpp}.each do |tax|
#        let(tax.to_sym) { Salaries::Tax.find_by_title(tax.upcase) }
#      end
#
#      it 'employee value total should be correct' do
#        salary.employee_value_total.should == (736.04).to_money
#      end
#
#      it 'net salary should be correct' do
#        salary.net_salary.should == (4263.96).to_money
#      end
#
#      describe 'AVS' do
#        let(:data) { salary.tax_data.where(:tax_id => avs.id).first }
#
#        it 'reference_value should be correct' do
#          data.reference_value.should == (5200).to_money
#        end
#
#        it 'taxed_value should be correct' do
#          data.taxed_value.should == (5200).to_money
#        end
#
#        it 'employer_percent should be correct' do
#          data.employer_percent.should == 4.2
#        end
#
#        it 'employer_value should be correct' do
#          data.employer_value.should == (218.4).to_money
#        end
#
#        it 'employee_percent should be correct' do
#          data.employee_percent.should == 4.2
#        end
#
#        it 'employee_value should be correct' do
#          data.employee_value.should == (218.4).to_money
#        end
#      end
#
#      describe 'IS' do
#        let(:data) { salary.tax_data.where(:tax_id => is.id).first }
#
#        it 'reference_value should be correct' do
#          data.reference_value.should == (5320).to_money
#        end
#
#        it 'taxed_value should be correct' do
#          data.taxed_value.should == (5320).to_money
#        end
#
#        it 'employer_percent should be correct' do
#          data.employer_percent.should == 0.0
#        end
#
#        it 'employer_value should be correct' do
#          data.employer_value.should == 0.to_money
#        end
#
#        it 'employee_percent should be correct' do
#          data.employee_percent.should == 9.73
#        end
#
#        it 'employee_value should be correct' do
#          data.employee_value.should == (517.64).to_money
#        end
#      end
#    end
  end
end
