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
# Table name: people_public_tags
#
# *person_id*::     <tt>integer</tt>
# *public_tag_id*:: <tt>integer</tt>
#--
# == Schema Information End
#++

class PeoplePublicTag < ApplicationRecord
  #################
  ### RELATIONS ###
  #################

  belongs_to :person
  belongs_to :public_tag
end
