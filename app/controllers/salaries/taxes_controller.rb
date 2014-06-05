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

class Salaries::TaxesController < ApplicationController

  layout false

  def self.model
    Salaries::Tax
  end

  load_and_authorize_resource

  monitor_changes :@tax

  def index
    respond_to do |format|
      format.json { render json: @taxes }
    end
  end

  def models
    models = Dir.glob("#{Rails.root}/app/models/salaries/taxes/*").map do |file|
      "Salaries::Taxes::#{File.basename(file, '.*').camelize}"
    end
    respond_to do |format|
      format.json { render json: { models: models } }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @tax.save
        format.json { render json: @tax }
      else
        format.json { render json: @tax.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @tax }
    end
  end

  def update
    respond_to do |format|
      if @tax.update_attributes(params[:tax])
        format.json { render json: @tax }
      else
        format.json { render json: @tax.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @tax.destroy
        format.json { render json: {} }
      else
        format.json { render json: @tax.errors, status: :unprocessable_entity}
      end
    end
  end

  def import_data

    authorize! :manage, Salaries::Tax

    respond_to do |format|
      if params[:file]
        @tax = Salaries::Tax.find(params[:id])

        if @tax.process_data(params[:file].read)
          format.html do
            flash[:notice] = I18n.t('common.notices.successfully_updated')
            redirect_to salaries_path
          end
          format.json do
            render json: @tax
          end
        else

          # bad file alert
          format.html do
            flash[:error] = I18n.t('admin.errors.wrong_file_format')
            redirect_to salaries_path
          end
          format.json do
            render json: {errors: {base: [I18n.t("admin.errors.wrong_file_format")]}}, status: :unprocessable_entity
          end
        end
      else

        # no file alert
        format.html do
          flash[:error] = I18n.t('admin.errors.no_file_submitted')
          redirect_to salaries_path
        end
        format.json do
          render json: {errors: {base: [I18n.t("admin.errors.no_file_submitted")]}}, status: :unprocessable_entity
        end
      end

    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: Salaries::Tax.count} }
    end
  end

end
