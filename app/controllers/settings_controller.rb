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

class SettingsController < ApplicationController

  layout 'application'

  skip_before_filter :authenticate_person!, :only => 'requires_browser_update'
  skip_before_filter :route_browser, :only => 'requires_browser_update'

  def index
    authorize! :index, Setting
    respond_to do |format|
      format.html
    end
  end

  def requires_browser_update
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
