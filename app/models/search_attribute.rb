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
# Table name: search_attributes
#
# *id*::       <tt>integer, not null, primary key</tt>
# *model*::    <tt>string(255), default(""), not null</tt>
# *name*::     <tt>string(255), default(""), not null</tt>
# *indexing*:: <tt>string(255), default("")</tt>
# *mapping*::  <tt>string(255), default("")</tt>
# *group*::    <tt>string(255), default("")</tt>
#--
# == Schema Information End
#++

# If you change a mapping inside db/seeds/elasticsearch, you'd reindex and restart the server:
#   rake elasticsearch:sync
#   touch tmp/restart.txt
class SearchAttribute < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker

  #################
  ### CALLBACK  ###
  #################

  serialize :mapping, Hash

  #################
  ### RELATIONS ###
  #################

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :model, :name, :indexing
  validates_uniqueness_of :name, :scope => :model

  # Validate fields of type 'string' length
  validates_length_of :model, :maximum => 255
  validates_length_of :name, :maximum => 255
  validates_length_of :indexing, :maximum => 65535
  validates_length_of :mapping, :maximum => 65535
  validates_length_of :group, :maximum => 255

  scope :searchable, where("#{table_name}.group <> ''")
  scope :orderable, searchable.where("#{table_name}.mapping NOT LIKE '%object%'")


  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)
    h[:searchable] = !group.blank?
    h[:orderable] = mapping.to_s.match(/object/).nil?
    h
  end


end
