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
# Table name: jobs
#
# *id*::          <tt>integer, not null, primary key</tt>
# *name*::        <tt>string(255), default("")</tt>
# *description*:: <tt>text, default("")</tt>
#--
# == Schema Information End
#++

class Job < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  include ElasticSearch::AutomaticPeopleReindexing


  #################
  ### RELATIONS ###
  #################
  has_many  :people


  ###################
  ### VALIDATIONS ###
  ###################
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name,
                      with: /\A[^,]+\z/i,
                      allow_blank: true,
                      message: :cannot_contain_comma
                      # message: I18n.t("job.errors.cannot_contain_comma")

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536


  ########################
  ### INSTANCE METHODS ###
  ########################
  def as_json(options = nil)
    h = super(options || {})
    h[:members_count] = people.count
    h
  end

end
