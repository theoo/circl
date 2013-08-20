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

class Salaries::SalaryTemplatesController < ApplicationController

  layout false

  def self.model
    Salaries::SalaryTemplate
  end

  load_and_authorize_resource

  monitor_changes :@salary_template

  def index
    respond_to do |format|
      format.json { render :json => @salary_templates }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @salary_template.save
        BackgroundTasks::GenerateSalaryTemplateJpg.process!(:salary_template_id => @salary_template.id)
        format.json { render :json => @salary_template }
      else
        format.json { render :json => @salary_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @salary_template }
    end
  end

  def update
    respond_to do |format|
      if @salary_template.update_attributes(params[:salary_template])
        BackgroundTasks::GenerateSalaryTemplateJpg.process!(:salary_template_id => @salary_template.id)
        format.json { render :json => @salary_template }
      else
        format.json { render :json => @salary_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @salary_template.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @salary_template.errors, :status => :unprocessable_entity}
      end
    end
  end

  def placeholders
    authorize! :manage, Salaries::SalaryTemplate

    st = Salaries::SalaryTemplate.new(:language => @current_person.main_communication_language)
    placeholders = st.placeholders

    respond_to do |format|
      format.json { render :json => placeholders }
    end
  end

end
