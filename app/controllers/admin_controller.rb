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

class AdminController < ApplicationController

  layout 'application'

  def index
    authorize! :index, Admin

    respond_to do |format|
      format.html { render }
    end
  end

  # TODO move this method to people_controller
  def confirm_people
    authorize! :confirm_people, Admin

    unless params[:people_file]
      flash[:alert] = I18n.t('admin.errors.no_file_submitted')
      redirect_to admin_path
      return
    end

    session[:people_file_data] = params[:people_file].read
    @infos = Person.parse_people(session[:people_file_data])

    respond_to do |format|
      format.html { render }
    end
  end

  # TODO move this method to people_controller
  def import_people
    authorize! :import_people, Admin

    people = Person.parse_people(session[:people_file_data])[:people]

    Person.transaction do
      people.each do |p|
        p.save!
      end
    end

    # In rails 3.1, session is a normal Hash
    # In rails 3.2, session is a CGI::Session
    begin
      session.delete(:people_file_data) # Rails 3.1
      session.data.delete(:people_file_data) # Rails 3.2
    rescue
    end

    PersonMailer.send_people_import_report(current_person, people).deliver
    flash[:notice] = I18n.t('admin.notices.people_imported', :email => current_person.email)
    Activity.create!(:person => current_person, :resource_type => 'Admin', :resource_id => '0', :action => 'info', :data => { :people => "imported at #{Time.now}" })
    redirect_to admin_path
  end

end
