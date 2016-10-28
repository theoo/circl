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
# Table name: languages
#
# *id*::   <tt>integer, not null, primary key</tt>
# *name*:: <tt>string(255), default("")</tt>
# *code*:: <tt>string(255), default("")</tt>
#--
# == Schema Information End
#++

class Language < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### CALLBACKS ###
  #################
  before_destroy :check_is_not_use_as_main_communication_language

  #################
  ### RELATIONS ###
  #################

  has_many :main_people,
           class_name: 'Person',
           foreign_key: :main_communication_language_id
  has_many  :invoice_templates
  has_many  :salaries_templates

  has_and_belongs_to_many :communication_people, #communication_languages
                          -> { distinct },
                          class_name: 'Person',
                          join_table: 'people_communication_languages',
                          after_add: :update_elasticsearch_index,
                          after_remove: :update_elasticsearch_index

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_uniqueness_of :name

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255
  validates_length_of :code, maximum: 255


  ########################
  ### INSTANCE METHODS ###
  ########################

  # Returns the code as a downcased symbol.
  def symbol
    # Code is user-defined, ensure it's existing.
    sym = self.code.downcase.to_sym
    I18n.available_locales.index(sym) ? sym : :en
  end

  def reindex_people_if_needed
    reindex_people unless self.changes.empty?
    true
  end

  def reindex_people
    ids = main_people.map(&:id) + communication_people.map(&:id)
    Synchronize::SearchEngineJob.perform_later(ids: ids.uniq)
    true
  end

  def as_json(options)
    h = super(options)

    h[:people_count] = [main_people.count, communication_people.count].join(", ")
    h[:errors] = errors

    h
  end

  def check_is_not_use_as_main_communication_language
    if main_people.count > 0
       errors.add(:base,
                 I18n.t('language.errors.cannot_destroy_main_communication_language_in_use'))
      false
    end
  end

end
