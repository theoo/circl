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

class People::Salaries::SalariesController < ApplicationController

  layout false

  def self.model
    Salaries::Salary
  end

  load_resource :person
  # load_and_authorize_resource :class => model, :through => :person
  load_resource :class => model, :through => :person

  monitor_changes :@salary

  def index
    respond_to do |format|
      format.json { render :json => @salaries }
    end
  end

  def show
    respond_to do |format|
      format.json { render :json => @salary }

      format.html do
        generator = AttachmentGenerator.new(@salary)
        render :inline => generator.html, :layout => 'preview'
      end

      format.pdf do
        if ! @salary.pdf_up_to_date? or ! @salary.pdf.exists?
          BackgroundTasks::GenerateSalaryPdf.process!(:salary_id => @salary.id)
          @salary.reload
        end
        send_data File.read(@salary.pdf.path),
          :filename => "salary_#{params[:id]}.pdf",
          :type => 'application/pdf'
      end

      format.odt do
        @odt = ""
        generator = AttachmentGenerator.new(@salary)
        generator.odt { |o,odt| @odt = odt.read }
        send_data @odt,
                  :filename => "salary_#{params[:id]}.odt",
                  :type => 'application/vnd.oasis.opendocument.text'
      end

    end
  end

  def create
    @salary.yearly_salary = Money.new(params[:yearly_salary].to_f * 100, params[:yearly_salary_currency])
    respond_to do |format|
      if @salary.save
        format.json { render :json => @salary }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @salary }
    end
  end

  def update
    @salary.yearly_salary = Money.new(params[:yearly_salary].to_f * 100, params[:yearly_salary_currency])
    params[:salary].delete(:yearly_salary)
    respond_to do |format|
      if @salary.update_attributes(params[:salary])
        format.json { render :json => @salary }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_items
    items = params[:items].each_with_object([]) do |(unused, attributes), arr|
      attributes[:tax_ids] ||= [] # make sure this is reset if not sent
      item = attributes.has_key?(:id) ? Salaries::Item.find(attributes[:id]) : Salaries::Item.new
      item.assign_attributes(attributes)
      item.salary_id = @salary.id # Override given salary
      arr << item
    end
    items.reject!{ |i| i.new_record? && i.empty? }

    # Validate each item separatly
    errors = items.reject(&:valid?).each_with_object({}) do |item, h|
      h[:base] = item.errors.messages.map do |k, arr|
        msg = I18n.t("item.views.line") + " " + (item.position + 1).to_s + ": "
        msg += "#{I18n.t("tax_data.views." + k.to_s)}: #{arr.join(',')}"
      end
    end

    removed_items = @salary.items.reject{ |i| items.include?(i) }
    # TODO Validate items positions
    # TODO move all this in ItemsController#update

    respond_to do |format|
      if errors.empty?
        # Save new items
        items.each(&:save!)

        # Delete removed items
        removed_items.each(&:destroy)

        format.json { render :json => @salary.reload }
      else
        format.json { render :json => errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_tax_data
    tax_data = params[:tax_data].each_with_object([]) do |(unused, attributes), arr|
      item = Salaries::TaxData.find(attributes[:id])
      item.assign_attributes(attributes)
      arr << item
    end

    # Validate each tax separatly
    errors = tax_data.reject(&:valid?).each_with_object({}) do |data, h|
      h[:base] = data.errors.messages.map do |k, arr|
        msg = I18n.t("item.views.line") + " " + (data.position + 1).to_s + ": "
        msg += "#{I18n.t("tax_data.views." + k.to_s)}: #{arr.join(',')}"
      end
    end

    # TODO Validate items positions
    # TODO move all this in TaxDataController#update

    respond_to do |format|
      if errors.size == 0
        # Save new items
        tax_data.each(&:save!)

        format.json { render :json => @salary.reload }
      else
        format.json { render :json => errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @salary.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity}
      end
    end
  end

end
