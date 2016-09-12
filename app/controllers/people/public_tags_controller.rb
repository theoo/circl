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

class People::PublicTagsController < ApplicationController

  layout false

  load_resource :person

  def self.model
    PeoplePublicTag
  end

  def index
    authorize! :index, self.class.model

    respond_to do |format|
      format.json { render json: @person.public_tags }
    end
  end

  def update
    authorize! [:create, :destroy], @person => self.class.model
    params[:public_tag_ids] ||= []

    respond_to do |format|
      if @person.update_attributes(public_tags_params)
        format.json  { render json: @person.public_tags }
      else
        format.json { render json: @person.errors, status: :unprocessable_entity}
      end
    end
  end

  private

    def public_tags_params
      params.permit(public_tag_ids: [])
    end

end
