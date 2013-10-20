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

class Salaries::SalariesController < ApplicationController

  layout false

  def self.model
    Salaries::Salary
  end

  load_and_authorize_resource

  monitor_changes :@salary

  def index
    respond_to do |format|
      format.json { render :json => @salaries }
    end
  end

  # Returns a list of the oldest salaries to pay which are not references.
  # The number of salaries is limited to 100 to prevent the dev of server-side pagination.
  def pending
    authorize! :pending_salaries, Salaries::Salary

    @salaries = Salaries::Salary.where(:paid => false, :is_reference => false)
                                .order("salaries.from DESC")
                                .limit(100)

    respond_to do |format|
      format.json { render :json => @salaries }
    end
  end

  # Member methods which copy the given reference salary to a group of people.
  def copy_reference
    respond_to do |format|

      @employees = []
      if @salary.is_reference?

        query = JSON.parse params[:query]
        query.symbolize_keys!

        if query[:search_string].blank?
          format.json { render :json => { :search_string => [I18n.t('activerecord.errors.messages.blank')] }, :status => :unprocessable_entity }
        else
          succeed_token = true
          Salaries::Salary.transaction do
            people_ids = ElasticSearch.search(query[:search_string], query[:selected_attributes], query[:attributes_order]).map(&:id)

            people_ids.each do |id|
              p = Person.find id
              @employees << p if p.can_have_salaries?
            end

            if @employees.size != people_ids.size
              flash[:alert] = I18n.t("salaries.salary.errors.one_or_more_people_doesnt_satisfy_requirements", 
                                {:people_ids => (people_ids -@employees.map(&:id))})
              succeed_token = false
              raise ActiveRecord::Rollback
            end

            @employees.each do |employee|
              # Don't copy to the reference salary owner.
              if @salary.person_id != employee.id
                new_salary = @salary.dup
                new_salary.person_id = employee.id
                unless new_salary.save
                  msg = I18n.t("salaries.salary.errors.something_prevented_salaries_to_be_saved")
                  msg += I18n.t("activerecord.models.person") + ": "
                  msg += employee.id
                  msg += I18n.t("activerecord.models.salary") + ": "
                  msg += new_salary.errors.map{|k,v| k.to_s + ":" + v.join(", ")}
                  flash[:alert] = msg
                  succeed_token = false
                  raise ActiveRecord::Rollback
                end
              end

            end
          end

          if succeed_token
            format.json { render :json => {} }
            format.html do
              # TODO improve report
              flash[:notice] = I18n.t("salaries.salary.notices.reference_were_copied", :members_count => @employees.size)
              redirect_to salaries_path(:anchor => 'payroll')
            end
          else
            format.json { render :json => { :error => [flash[:alert]] }, :status => :unprocessable_entity }
            format.html do
              flash[:notice] = I18n.t("salaries.salary.notices.plese_try_again")
              redirect_to salaries_path(:anchor => 'payroll')
            end
          end
        end
      else
        format.json { render :json => { :error => [I18n.t('salaries.salary.is_not_a_reference')] }, :status => :unprocessable_entity }
      end
    end
  end

  def export
    from = Date.parse(params[:from]) if validate_date_format(params[:from])
    to   = Date.parse(params[:to]) if validate_date_format(params[:to])

    # select all salaries which are not references
    salaries_arel = Salaries::Salary.where(:is_reference => false)

    # select paid or not
    if params[:paid] and not params[:unpaid]
      salaries_arel = salaries_arel.where(:paid => true)
    elsif params[:unpaid] and not params[:paid]
      salaries_arel = salaries_arel.where(:paid => false)
    end

    respond_to do |format|
      format.html do
        if from && to
          salaries = salaries_arel.where('salaries.from >= ? AND salaries.to <= ?', from, to).order('salaries.from ASC')
          exporter = Exporter::Factory.new( :salaries,
                                            :salary_details )
          send_data( exporter.export(salaries),
                     :type => 'application/octet-stream',
                     :filename=> "salaries_#{from}_#{to}_#{params[:type]}.csv",
                     :disposition => 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to salaries_path
        end
      end
    end
  end

  def export_accounting
    from = Date.parse(params[:from]) if validate_date_format(params[:from])
    to   = Date.parse(params[:to]) if validate_date_format(params[:to])

    # select all salaries which are not references
    salaries_arel = Salaries::Salary.where(:is_reference => false)

    # select paid or not
    if params[:paid] and not params[:unpaid]
      salaries_arel = salaries_arel.where(:paid => true)
    elsif params[:unpaid] and not params[:paid]
      salaries_arel = salaries_arel.where(:paid => false)
    end

    respond_to do |format|
      format.html do
        if from && to
          salaries = salaries_arel.where('salaries.from >= ? AND salaries.to <= ?', from, to).order(:created_at)
          extention = params[:type] == 'banana' ? 'txt' : 'csv'
          exporter = Exporter::Factory.new( :salaries_and_taxes,
                                            params[:type].to_sym,
                                            {:employer_part => params[:employer_part]})
          send_data( exporter.export(salaries),
                     :type => 'application/octet-stream',
                     :filename=> "salaries_#{from}_#{to}_#{params[:type]}.#{extention}",
                     :disposition => 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to salaries_path
        end
      end
    end
  end

  def export_ocas
    if params[:year]
      year = params[:year]
      from = Date.new(params[:year].to_i, 1, 1)
      to   = Date.new(params[:year].to_i, 12, 31)
    else
      from = Date.parse(params[:from]) if validate_date_format(params[:from])
      to   = Date.parse(params[:to]) if validate_date_format(params[:to])
    end

    respond_to do |format|
      format.html do
        if from && to
          salaries = Salaries::Salary.interval(from, to)
          exporter = Exporter::Factory.new( :custom, :ocas)
          send_data( exporter.export(salaries),
                     :type => 'application/octet-stream',
                     :filename=> "ocas_#{from}_#{to}_#{params[:type]}.csv",
                     :disposition => 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to salaries_path
        end
      end
    end
  end

  def export_certificates
    if params[:year]
      year = params[:year]
      from = Date.new(params[:year].to_i, 1, 1)
      to   = Date.new(params[:year].to_i, 12, 31)
    else
      from = Date.parse(params[:from]) if validate_date_format(params[:from])
      to   = Date.parse(params[:to]) if validate_date_format(params[:to])
    end

    respond_to do |format|
      format.html do
        if from && to
          salaries = Salaries::Salary.interval(from, to)
          exporter = Exporter::Factory.new( :custom, :elohnausweisssk )
          send_data( exporter.export(salaries),
                     :type => 'application/octet-stream',
                     :filename=> "elohnausweissk_#{from}_#{to}_#{params[:type]}.csv",
                     :disposition => 'attachment' )
        else
          flash[:alert] = I18n.t('common.errors.date_must_match_format')
          redirect_to salaries_path
        end
      end
    end
  end

  def available_years
    if Salaries::Salary.count > 0
      from = Salaries::Salary.order('salaries.from ASC').first.from.year
      to   = Salaries::Salary.order('salaries.to ASC').last.to.year

      years = { :from => from, :to => to }
    else
      years = { :from => Time.now.year - 5, :to => Time.now.year }
    end

    respond_to do |format|
      format.json { render :json => years }
    end
  end

  def update
    respond_to do |format|
      if @salary.update_attributes(params[:salary])
        format.json { render :json => @salary }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity }
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
