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

class People::DashboardController < ApplicationController

  load_resource :person

  layout false

  def index
    @person = params[:id] ? Person.find(params[:id]) : current_person

    respond_to do |format|
      format.html { render :layout => 'application' }
    end
  end

  def comments
    @comments = Comment.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render :json => @comments }
    end
  end

  def activities
    @activities = @person.activities.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render :json => @activities }
    end
  end

  def last_people_added
    @last_people_added = Person.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render :json => @last_people_added }
    end
  end

  def open_invoices
    @open_invoices = Invoice.open_invoices.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render :json => @open_invoices }
    end
  end
end
