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

class Settings::TaskRatesController < ApplicationController

  layout false

  load_and_authorize_resource

  def index

    @task_rates = TaskRate.actives if params[:actives]

    respond_to do |format|
      format.json { render json: @task_rates }
    end
  end

  def show
    edit
  end

  def create
    @task_rate = TaskRate.new(task_rate_params)
    @task_rate.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @task_rate.save
        format.json { render json: @task_rate }
      else
        format.json { render json: @task_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @task_rate }
    end
  end

  def update
    @task_rate.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @task_rate.update_attributes(task_rate_params)
        format.json { render json: @task_rate }
      else
        format.json { render json: @task_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @task_rate.destroy
        format.json { render json: {} }
      else
        format.json { render json: @task_rate.errors, status: :unprocessable_entity}
      end
    end
  end

  private

    def task_rate_params
      params.require(:task_rate).permit(
        :title,
        :description,
        :value_in_cents,
        :value_currency,
        :archive,
        :created_at,
        :updated_at
      )
    end

end
