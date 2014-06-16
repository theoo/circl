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
    authorize! :dashboard_index, @person
    @person = params[:id] ? Person.find(params[:id]) : current_person

    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  def comments
    authorize! :dashboard_comments, @person
    respond_to do |format|
      format.json { render json: OpenCommentsDatatable.new(view_context) }
    end
  end

  def activities
    authorize! :dashboard_activities, @person
    @activities = @person.activities.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render json: @activities }
    end
  end

  def last_people_added
    authorize! :dashboard_last_people_added, @person
    @last_people_added = Person.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render json: @last_people_added }
    end
  end

  def open_invoices
    authorize! :dashboard_open_invoices, @person
    respond_to do |format|
      format.json { render json: OpenInvoicesDatatable.new(view_context) }
    end
  end

  def current_affairs
    authorize! :dashboard_current_affairs, @person
    respond_to do |format|
      format.json { render json: OpenAffairsDatatable.new(view_context) }
    end
  end

  def open_salaries
    authorize! :dashboard_open_salaries, @person
    @open_salaries = Salaries::Salary.unpaid_salaries.order("created_at desc").limit(10)

    respond_to do |format|
      format.json { render json: OpenSalariesDatatable.new(view_context) }
    end
  end
end
