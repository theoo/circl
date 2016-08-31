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

class BackgroundTasksController < ApplicationController

  layout false

  def index
    # TODO refactor permissions
    authorize! :index, Person

    @tasks = Resque::Plugins::Status::Hash.statuses

    respond_to do |format|
      format.json { }
    end
  end

  def destroy
    # TODO refactor permissions
    authorize! :destroy, Person

    respond_to do |format|
      if @task.kill(params[:job_id])
        format.json { render json: {} }
      else
        format.json do
          errors = { errors: { base: [I18n.t("admin.jobs.errors.unable_to_destroy")]} }
          render json: errors, status: :unprocessable_entity
        end
      end
    end
  end

end
