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

class People::CommunicationLanguagesController < ApplicationController

  layout false

  load_resource :person

  def self.model
    PeopleCommunicationLanguage
  end

  def index
    authorize! :index, self.class.model
    @communication_languages = @person.communication_languages

    respond_to do |format|
      format.json { render json: @communication_languages }
    end
  end

  def update
    authorize! [:create, :update], @person => self.class.model

    respond_to do |format|
      if @person.update_attributes(communication_language_ids: params[:communication_language_ids])
        format.json { render json: @person.communication_languages }
      else
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

end
