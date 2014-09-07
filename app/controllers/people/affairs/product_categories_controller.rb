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

class People::Affairs::ProductCategoriesController < ApplicationController

  layout false

  load_resource :person
  load_resource :affair

  def self.model
    AffairsProductsCategory
  end

  def index
    authorize! :index, AffairsProductsCategory
    @categories = @affair.product_categories.order(:position)

    respond_to do |format|
      format.json do
        render json: @categories
      end
    end
  end

  def update
    authorize! :manage, AffairsProductsCategory

    success = false

    AffairsProductsCategory.transaction do
      params[:ids].each_with_index do |c, i|
        AffairsProductsCategory.find(c).update_attributes(position: i + 1)
      end
      success = true
    end

    respond_to do |format|
      if success
        format.json { render json: @categories }
      else
        format.json { render json: "Unable to update order", status: :unprocessable_entity }
      end
    end
  end
end
