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

class People::Salaries::ItemsController < ApplicationController

  layout false

  def self.model
    Salaries::Item
  end

  load_resource :person
  load_resource :salary, class: ::Salaries::Salary
  load_resource class: model, through: :salary

  def index
    respond_to do |format|
      format.json { render json: @items }
    end
  end

  def compute_value_for_next_salaries
    # TODO refactor this into a generic lib and use that

    @item = Salaries::Item.find(params[:id])
    target = params[:target].to_money

    reference  = @item.is_reference? ? @item : @item.reference
    siblings = reference.siblings

    siblings_count = siblings.count
    siblings_sum   = siblings.map(&:value).sum

    salary_reference    = @salary.is_reference ? @salary : @salary.reference
    future_items_count = salary_reference.yearly_salary_count - siblings_count
    yearly_items_sum   = (target * salary_reference.yearly_salary_count)

    value = (yearly_items_sum - siblings_sum) / future_items_count

    respond_to do |format|
      format.json { render json: { value: value.to_f } }
    end
  end

  def compute_value_for_this_salary
    # TODO refactor this into a generic lib and use that

    @item = Salaries::Item.find(params[:id])

    reference  = @item.is_reference? ? @item : @item.reference
    siblings = reference.siblings

    siblings_count = siblings.size
    siblings_sum   = siblings.map(&:value).sum

    salary_reference    = @salary.is_reference ? @salary : @salary.reference
    future_items_count = salary_reference.yearly_salary_count - siblings_count - 1

    yearly_items_sum   = (reference.value * salary_reference.yearly_salary_count)
    value = yearly_items_sum - (siblings_sum + (reference.value * future_items_count))

    respond_to do |format|
      format.json { render json: { value: value.to_f } }
    end
  end

end
