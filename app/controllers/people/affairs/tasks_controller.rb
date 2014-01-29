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

  monitor_changes :@task

  def index
    authorize! :index, ::Task

    @affair = Affair.find(params[:affair_id])
    @tasks = @affair.tasks

    respond_to do |format|
      format.json { render :json => @tasks }
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
        render :inline => csv_ify(@tasks, fields)
     end

      format.pdf do
        # TODO Allow user to edit this pdf listing through a template
        html = render_to_string(:layout => 'pdf.html.haml')

        html.assets_to_full_path!

        file = Tempfile.new(['tasks', '.pdf'], :encoding => 'ascii-8bit')
        file.binmode
        file.write(PDFKit.new(html).to_pdf)
        file.flush

        send_data File.read(file), :filename => "affair_#{params[:affair_id]}_tasks.pdf", :type => 'application/pdf'

        file.unlink
      end
    end
  end

  def show
    edit
  end

  def create
    authorize! :create, ::Task

    @task = ::Task.new(params[:task])
    override_posted_values

    respond_to do |format|
      if @task.save
        format.json { render :json => @task }
      else
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :read, ::Task
    respond_to do |format|
      format.json { render :json => @task }
    end
  end

  def update
    authorize! :update, ::Task

    @task = ::Task.find(params[:id])
    override_posted_values

    respond_to do |format|
      if @task.update_attributes(params[:task])
        format.json { render :json => @task }
      else
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, ::Task

    @task = ::Task.find(params[:id])

    respond_to do |format|
      if @task.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @task.errors, :status => :unprocessable_entity}
      end
    end
  end

  private

  def override_posted_values
    @task.affair_id = params[:affair_id]
    @task.executer_id = current_person.id
    @task.value = Money.new(params[:value].to_f * 100, params[:value_currency])
  end

end
