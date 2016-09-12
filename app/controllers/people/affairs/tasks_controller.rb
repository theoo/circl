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

class People::Affairs::TasksController < ApplicationController

  layout false

  def index
    authorize! :index, ::Task

    @affair = Affair.find(params[:affair_id])
    @tasks = @affair.tasks

    reference = @tasks.first

    if params[:template_id]
      reference.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @tasks }

      format.csv do
        fields = []
        fields << 'id'
        fields << 'start_date'
        fields << 'end_date'
        fields << 'duration'
        fields << 'task_type.title'
        fields << 'description'
        fields << 'executer.name'
        fields << 'value'
        render inline: csv_ify(@tasks, fields)
      end

      if params[:template_id]
        format.html do
          generator = AttachmentGenerator.new(@tasks, reference)
          render inline: generator.html, layout: 'preview'
        end

        format.pdf do
          @pdf = ""
          generator = AttachmentGenerator.new(@tasks, reference)
          generator.pdf { |o,pdf| @pdf = pdf.read }
          send_data @pdf,
                    filename: "affair_tasks_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator = AttachmentGenerator.new(@tasks, reference)
          generator.odt { |o,odt| @odt = odt.read }
          send_data @odt,
                    filename: "affair_tasks_#{params[:affair_id]}.odt",
                    type: 'application/vnd.oasis.opendocument.text'
        end
      end
    end
  end

  def show
    edit
  end

  def create
    authorize! :create, ::Task

    @task = ::Task.new(task_params)
    override_posted_values

    respond_to do |format|
      if @task.save
        format.json { render json: @task }
      else
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :read, ::Task
    respond_to do |format|
      format.json { render json: @task }
    end
  end

  def update
    authorize! :update, ::Task

    @task = ::Task.find(params[:id])
    override_posted_values

    respond_to do |format|
      if @task.update_attributes(task_params)
        format.json { render json: @task }
      else
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, ::Task

    @task = ::Task.find(params[:id])

    respond_to do |format|
      if @task.destroy
        format.json { render json: {} }
      else
        format.json { render json: @task.errors, status: :unprocessable_entity}
      end
    end
  end

  private

    def override_posted_values
      @task.affair_id = params[:affair_id]
      @task.executer_id = current_person.id
      @task.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    end

    def task_params
      params.require(:task).permit(
        :executer_id,
        :executer_name,
        :creator_id,
        :creator_name,
        :description,
        :duration,
        :affair_id,
        :task_type_id,
        :value_in_cents,
        :value_currency,
        :salary_id,
        :start_date,
        :created_at,
        :updated_at
        )
    end

end
