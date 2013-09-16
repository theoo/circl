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
  load_resource :salary, :class => ::Salaries::Salary
  load_resource :class => model, :through => :salary

  def index
    respond_to do |format|
      format.json { render :json => @items }
    end
  end

  def compute_value_for_next_salaries
    # TODO refactor this into a generic lib and use that

    @item = Salaries::Item.find(params[:id])
    target = params[:target].to_f

    item_reference  = @item.is_reference? ? @item : @item.reference
    existing_items = item_reference.reference
    unless @item.salary.is_reference?
      existing_items.reject!{ |i| i.id == @item.id }
    end

    existing_items_count = existing_items.count
    existing_items_sum   = existing_items.map(&:value).sum.to_f

    salary_reference    = @salary.is_reference ? @salary : @salary.reference
    future_items_count = salary_reference.yearly_salary_count - existing_items_count
    yearly_items_sum   = (target * salary_reference.yearly_salary_count)

    value = (yearly_items_sum - existing_items_sum) / future_items_count.to_f

    respond_to do |format|
      format.json { render :json => { :value => value } }
    end
  end

  def compute_value_for_this_salary
    # TODO refactor this into a generic lib and use that

    @item = Salaries::Item.find(params[:id])

    item_reference  = @item.is_reference? ? @item : @item.reference
    existing_items = item_reference.reference
    unless @item.is_reference?
      existing_items.reject!{ |i| i.id == @item.id }
    end

    existing_items_count = existing_items.size
    existing_items_sum   = existing_items.map(&:value).sum.to_f

    salary_reference    = @salary.is_reference ? @salary : @salary.reference
    future_items_count = salary_reference.yearly_salary_count - existing_items_count - 1

    yearly_items_sum   = (item_reference.value.to_f * salary_reference.yearly_salary_count)
    value = yearly_items_sum - (existing_items_sum + (future_items_count * item_reference.value.to_f))

    respond_to do |format|
      format.json { render :json => { :value => value } }
    end
  end

end
