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
# Table name: query_presets
#
# *id*::    <tt>integer, not null, primary key</tt>
# *name*::  <tt>string(255), default("")</tt>
# *query*:: <tt>text, default("")</tt>
#--
# == Schema Information End
#++

class QueryPreset < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker

  #################
  ### CALLBACKS ###
  #################

  after_initialize :set_default_query

  #################
  ### RELATIONS ###
  #################

  default_scope { order('name ASC') }
  serialize :query

  ###################
  ### VALIDATIONS ###
  ###################

  # TODO, ensure query store required hash values list selected_attributes and ordered_attributes
  validates_presence_of   :name, :query
  validates_uniqueness_of :name

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255

  before_destroy do
    errors.add :base, I18n.t("search_attributes.errors.unable_to_destroy_default_query_preset")
    false
  end

  private

  def set_default_query
    self.query ||= { selected_attributes: [], attributes_order: [] }
  end

end
