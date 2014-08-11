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
# Table name: translation_aptitudes
#
# *id*::               <tt>integer, not null, primary key</tt>
# *person_id*::        <tt>integer</tt>
# *from_language_id*:: <tt>integer</tt>
# *to_language_id*::   <tt>integer</tt>
#--
# == Schema Information End
#++

class TranslationAptitude < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing

  #################
  ### CALLBACKS ###
  #################

  after_commit :update_elasticsearch

  #################
  ### RELATIONS ###
  #################
  belongs_to  :person
  belongs_to  :from_language, class_name: 'Language'
  belongs_to  :to_language, class_name: 'Language'


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :person_id
  validates_presence_of :from_language
  validates_presence_of :to_language

  validate :translation_aptitude_is_unique, if: :person
  validate :translation_aptitude_languages_should_be_different


  ########################
  ### INSTANCE METHODS ###
  ########################

  def translation_aptitude_is_unique
    # TODO rewrite this the proper way
    ta = person.translation_aptitudes.map{|t| [t.from_language, t.to_language]}
    ta << [from_language, to_language]

    if ta.uniq != ta
      errors.add(:base,
                 I18n.t('translation_aptitude.errors.translation_aptitude_should_be_uniq_for_a_person'))
      return false
    end
  end

  def translation_aptitude_languages_should_be_different
    if from_language == to_language
      errors.add(:base,
                 I18n.t('translation_aptitude.errors.translation_aptitude_languages_should_be_different'))
      return false
    end
  end

  def as_string
    "#{from_language.name} -> #{to_language.name}"
  end


  private

  def update_elasticsearch
    person.update_index unless self.changes.empty?
  end

end
