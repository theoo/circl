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

class People::Affairs::SubscriptionsController < ApplicationController

  layout false

  load_resource :person
  load_resource :affair

  monitor_changes :@affair

  def self.model
    AffairsSubscription
  end

  def index
    authorize! :index, self.class.model
    @subscriptions = @affair.subscriptions

    respond_to do |format|
      format.json do
        subs = []
        @subscriptions.map do |s|
          h = s.to_hash
          # Add current value for this person
          h[:value] = s.value_for(@person).to_f
          h[:value_currency] = s.value_for(@person).currency.try(:iso_code)
          subs << h
        end
        render json: subs
      end
    end
  end

  def create
    authorize! :create, @affair => self.class.model

    # validate_params(:subscription_id)
    respond_to do |format|
      if ! params[:subscription_id].empty?
        subscription = Subscription.find params[:subscription_id]
        @affair.subscriptions << subscription

        format.json { render json: subscription }
      else
        format.json { render json: { subscription_id: [I18n.t('activerecord.errors.messages.blank')] }, status: :unprocessable_entity }
      end
    end

  end

  def destroy
    authorize! :destroy, @affair => self.class.model
    @affair.subscription_ids -= [params[:subscription_id].to_i]
    respond_to do |format|
      format.json { render json: {} }
    end
  end

end
