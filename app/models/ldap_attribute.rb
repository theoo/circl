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

# == Schema Information
#
# Table name: ldap_attributes
#
# *id*::         <tt>integer, not null, primary key</tt>
# *name*::       <tt>string(255), not null</tt>
# *mapping*::    <tt>string(255), not null</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#--
# == Schema Information End
#++

class LdapAttribute < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_presence_of :mapping
  validates_uniqueness_of :name

end
