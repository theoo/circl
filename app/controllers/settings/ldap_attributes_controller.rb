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

class Settings::LdapAttributesController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@ldap_attribute

  def index
    respond_to do |format|
      format.json { render :json => @ldap_attributes }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @ldap_attribute.save
        format.json  { render :json => @ldap_attribute }
      else
        format.json  { render :json => @ldap_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json  { render :json => @ldap_attribute }
    end
  end

  def update
    respond_to do |format|
      if @ldap_attribute.update_attributes(params[:ldap_attribute])
        format.json  { render :json => @ldap_attribute }
      else
        format.json  { render :json => @ldap_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @ldap_attribute.destroy
        format.json  { render :json => {} }
      else
        format.json  { render :json => @ldap_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end

  def synchronize
    if BackgroundTasks::RunRakeTask.schedule(:name => 'ldap:sync')
      Activity.create!(:person => current_person, :resource_type => 'LdapAttribute', :resource_id => '0', :action => 'info', :data => { :synchronize => "Sync started at #{Time.now}" })
      flash[:notice] = I18n.t('common.notices.synchronization_started', :email => current_person.email)
    else
      flash[:alert] = I18n.t('common.errors.already_synchronizing')
    end

    redirect_to settings_path
  end

end
