=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class People::Salaries::TaxDataController < ApplicationController

  layout false

  def self.model
    Salaries::TaxData
  end

  load_resource :person
  load_resource :salary, :class => Salaries::Salary
  load_resource :class => model, :through => :salary

  def index
    respond_to do |format|
      format.json { render :json => @tax_data }
    end
  end

  def reset
    @tax_data = Salaries::TaxData.find(params[:id])

    @tax_data.reset

    keys = %w{employer employee}.each_with_object([]) do |prefix, arr|
      %w{value percent use_percent}.each do |postfix|
        arr << "#{prefix}_#{postfix}"
      end
    end

    json = @tax_data.as_json.select { |key, value| keys.include?(key.to_s) }

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def compute_value_for_next_salaries
    # TODO refactor this into a generic lib and use that
    @tax_data = Salaries::TaxData.find(params[:id])
    targets = params[:targets]

    tax_data_reference  = @tax_data.is_reference? ? @tax_data : @tax_data.reference
    existing_tax_datas = tax_data_reference.children
    unless @tax_data.is_reference?
      existing_tax_datas.reject!{ |i| i.id == @tax_data.id }
    end

    existing_tax_datas_count = existing_tax_datas.count

    salary_reference = @salary.is_reference ? @salary : @salary.reference

    json = %w{employer_value employee_value}.map(&:to_sym).each_with_object({}) do |key, h|
      existing_tax_datas_sum = existing_tax_datas.map(&key).sum.to_f
      future_tax_datas_count = salary_reference.yearly_salary_count - existing_tax_datas_count
      yearly_tax_datas_sum   = (targets[key].to_f * salary_reference.yearly_salary_count)
      h[key] = (yearly_tax_datas_sum - existing_tax_datas_sum) / future_tax_datas_count.to_f
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def compute_value_for_this_salary
    # TODO refactor this into a generic lib and use that
    @tax_data = Salaries::TaxData.find(params[:id])
    targets = params[:targets]

    tax_data_reference  = @tax_data.is_reference? ? @tax_data : @tax_data.reference
    existing_tax_datas = tax_data_reference.children
    unless @tax_data.is_reference?
      existing_tax_datas.reject!{ |i| i.id == @tax_data.id }
    end

    existing_tax_datas_count = existing_tax_datas.size

    salary_reference = @salary.is_reference ? @salary : @salary.reference

    json = %w{employer_value employee_value}.map(&:to_sym).each_with_object({}) do |key, h|
      existing_tax_datas_sum = existing_tax_datas.map(&key).sum.to_f
      future_tax_datas_count = salary_reference.yearly_salary_count - existing_tax_datas_count - 1
      yearly_tax_datas_sum   = (tax_data_reference.send(key).to_f * salary_reference.yearly_salary_count)
      h[key] = yearly_tax_datas_sum - (existing_tax_datas_sum + (future_tax_datas_count * tax_data_reference.send(key).to_f))
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

end
