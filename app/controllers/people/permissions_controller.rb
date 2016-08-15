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

class People::PermissionsController < ApplicationController

  layout false

  def index
    person = Person.find(params[:person_id]) if Person.exists?(params[:person_id])
    hash = params[:can].each_with_object({}) do |(model, permissions), h|
      h[model] ||= {}
      permissions.each do |permission|
        begin
          if person
            subject = (model == 'person') ? person : { person => model.classify.constantize }
          else
            subject = model.classify.constantize
          end
        rescue
          subject = false
        end
        h[model][permission] = can?(permission.to_sym, subject)
      end
    end
    respond_to do |format|
      format.json { render json: hash }
    end
  end

end
