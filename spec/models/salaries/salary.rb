# encoding: utf-8

require 'spec_helper'

describe Salaries::Salary do
  let(:salary) {FactoryGirl.create(:salary)}

  describe 'validations' do

    it 'should have a title' do
      salary.title = nil
      salary.should have(1).error_on(:title)
    end

    it "should have a from date" do
      salary.from = nil
      salary.should have(1).error_on(:from)
    end

    it "should have a to date" do
      salary.to = nil
      salary.should have(1).error_on(:to)
    end

    it "should have children_count set" do
      salary.children_count = nil
      salary.should have(1).error_on(:children_count)
    end

    it "should have a salary template" do
      salary.salary_template_id = nil
      salary.should have(1).error_on(:salary_template_id)
    end

    it "should have an employee" do
      salary.person_id = nil
      salary.should have(1).error_on(:person_id)
    end

    it "should not overlap two years" do
      salary = FactoryGirl.create(:salary)
      salary.from  = Date.new(2012,11,30)
      salary.to    = Date.new(2013,1,31)

      salary.should have(1).error_on(:from)
      salary.should have(1).error_on(:to)
    end

    it "from should be before to" do
      salary.from = Date.new(2013,1,31)
      salary.to   = Date.new(2013,1,1)

      salary.should have(1).error_on(:from)
      salary.should have(1).error_on(:to)
    end

    it "its employee should have all required fields set" do
      salary.person.avs_number = nil
      salary.should have(1).error_on(:base)
    end
  end

  describe 'references validations' do
    it "should not be possible to destroy a reference if it has children salaries" do
      child = FactoryGirl.create(:salary)
      parent = FactoryGirl.create(:salary)
      child.reference = parent

      expect { salary.destroy }.to_not change(Salaries::Salary, :count)
    end
  end

  describe "financial objects and methods" do
    methods = [ :gross_pay, :net_salary, :employer_value_total, :employee_value_total ]
    objects = [ :yearly_salary, :cert_food, :cert_transport, :cert_food, :cert_logding,
                :cert_misc_salary_car, :cert_misc_salary_other_value,
                :cert_non_periodic_value, :cert_capital_value, :cert_participation,
                :cert_compentation_admin_members, :cert_misc_other_value, :cert_avs_ac_aanp,
                :cert_lpp, :cert_buy_lpp, :cert_is, :cert_alloc_traveling, :cert_alloc_food,
                :cert_alloc_other_actual_cost_value, :cert_alloc_representation,
                :cert_alloc_car, :cert_alloc_other_fixed_fees_value, :cert_formation ]
    methods.each do |o|
      it "Method #{o} should returns a Money object" do
        salary.send(o).should be_instance_of Money
      end
    end

    objects.each do |o|
      it "Object #{o} should returns a Money object" do
        salary.send(o).should be_instance_of Money
      end
    end
  end

end
