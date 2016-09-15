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
# Table name: locations
#
# *id*::                 <tt>integer, not null, primary key</tt>
# *parent_id*::          <tt>integer</tt>
# *name*::               <tt>string(255), default("")</tt>
# *iso_code_a2*::        <tt>string(255), default("")</tt>
# *iso_code_a3*::        <tt>string(255), default("")</tt>
# *iso_code_num*::       <tt>string(255), default("")</tt>
# *postal_code_prefix*:: <tt>string(255), default("")</tt>
# *phone_prefix*::       <tt>string(255), default("")</tt>
#--
# == Schema Information End
#++

class Location < ApplicationRecord

  #################
  ### CALLBACKS ###
  #################

  before_destroy :ensure_it_has_no_relations

  ################
  ### INCLUDES ###
  ################

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  #################
  ### RELATIONS ###
  #################

  has_many :people

  # TODO: Raises deprecation warning
  acts_as_tree

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :postal_code_prefix
  validates_uniqueness_of :iso_code_a2, :iso_code_a3, :iso_code_num, allow_nil: true, allow_blank: true
  validates_presence_of :parent_id, unless: :is_root?
  validate :existence_of_parent_id, unless: :is_root?

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255
  validates_length_of :iso_code_a2, maximum: 255
  validates_length_of :iso_code_a3, maximum: 255
  validates_length_of :iso_code_num, maximum: 255
  validates_length_of :postal_code_prefix, maximum: 255
  validates_length_of :phone_prefix, maximum: 255


  ########################
  ### INSTANCE METHODS ###
  ########################

  def is_root?
    name == 'earth' # TODO do we want to hardcode 'earth' here?
  end

  def country
    is_country? ? self : parent.try(:country)
  end

  def is_country?
    # TODO can this possibly bug?
    !iso_code_a2.blank?
  end

  def full_name
    if postal_code_prefix
      [postal_code_prefix, name].join(" ")
    else
      name
    end
  end

  def npa_town
    return '' if is_country?
    if postal_code_prefix
      "#{postal_code_prefix} #{name}"
    else
      name
    end
  end

  def as_json(options)
    h = super(options)

    h[:parent_name] = parent.try(:name)
    h[:people_count] = people.count
    h[:errors] = errors

    h
  end

  private

  def existence_of_parent_id
    unless Location.exists?(parent_id)
      errors.add(:parent_id,
                 I18n.t('location.errors.no_parent_location'))
    end
  end

  def ensure_it_has_no_relations
    if self.people.size > 0
      errors.add(:base,
                 I18n.t('location.errors.cannot_destroy_location_if_people_depend_on_it'))
      false
    end
  end

end
