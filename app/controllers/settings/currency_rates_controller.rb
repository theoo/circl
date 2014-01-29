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

class Settings::CurrencyRatesController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@currency_rate

  def index
    respond_to do |format|
      format.json do
        render :json => @currency_rates
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @currency_rate.save
        Money.default_bank.update_rates
        format.json do
          render :json => @currency_rate
        end
      else
        format.json { render :json => @currency_rate.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @currency_rate }
    end
  end

  def update
    respond_to do |format|
      if @currency_rate.update_attributes(params[:currency_rate])
        Money.default_bank.update_rates
        format.json do
          render :json => @currency_rate
        end
      else
        format.json { render :json => @currency_rate.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @currency_rate.destroy
        Money.default_bank.update_rates
        format.json { render :json => {} }
      else
        format.json { render :json => @currency_rate.errors, :status => :unprocessable_entity }
      end
    end
  end

  def exchange
    m = Money.new(params[:current_value].to_f * 100, params[:current_currency])
    target_value = m.exchange_to(params[:target_currency])

    respond_to do |format|
      format.json { render :json => {:target_value => target_value.to_view} }
    end
  end

end
