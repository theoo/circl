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
# Table name: affairs_subscriptions
#
# *affair_id*::       <tt>integer</tt>
# *subscription_id*:: <tt>integer</tt>
#--
# == Schema Information End
#++

class AffairsSubscription < ActiveRecord::Base

  #################
  ### RELATIONS ###
  #################

  belongs_to :affair
  belongs_to :subscription


  ###################
  ### VALIDATIONS ###
  ###################

  validates_uniqueness_of :subscription_id, scope: :affair_id
end
