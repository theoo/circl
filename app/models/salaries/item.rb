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
# Table name: salaries_items
#
# *id*::             <tt>integer, not null, primary key</tt>
# *parent_id*::      <tt>integer</tt>
# *salary_id*::      <tt>integer, not null</tt>
# *position*::       <tt>integer, not null</tt>
# *title*::          <tt>string(255), not null</tt>
# *value_in_cents*:: <tt>integer, not null</tt>
# *category*::       <tt>string(255)</tt>
# *created_at*::     <tt>datetime</tt>
# *updated_at*::     <tt>datetime</tt>
#--
# == Schema Information End
#++

class Salaries::Item < ActiveRecord::Base

  #################
  ### CALLBACKS ###
  #################

  after_create do
    if salary.is_reference
      salary.synchronize_tax_data
    end
  end

  after_update do
    salary.synchronize_tax_data
  end

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  #################
  ### RELATIONS ###
  #################

  belongs_to :salary,
             :class_name => 'Salaries::Salary'
  monitored_habtm :taxes,
                  :class_name => 'Salaries::Tax',
                  :join_table => 'salaries_items_taxes'

  # Template
  belongs_to :reference,
             :class_name => 'Salaries::Item',
             :foreign_key => :parent_id

  # money
  money :value

  ###############
  #### SCOPE ####
  ###############

  default_scope order('position ASC')
  scope :with_category, where('length(category) > 0')

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates_presence_of :value

  # Validate fields of type 'string' length
  validates_length_of :title, :maximum => 255
  validates_length_of :category, :maximum => 255


  ########################
  ### INSTANCE METHODS ###
  ########################

  def is_reference?
    salary.is_reference?
  end

  def empty?
    # FIXME add more
    title.blank? && category.blank?
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:tax_ids] = tax_ids
    h[:value] = value.to_f

    h[:errors] = errors
    h
  end

  def has_reference?
    reference.nil? == false
  end

end
