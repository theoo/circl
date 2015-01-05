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
# Table name: private_tags
#
# *id*::        <tt>integer, not null, primary key</tt>
# *parent_id*:: <tt>integer</tt>
# *name*::      <tt>string(255), default(""), not null</tt>
#--
# == Schema Information End
#++

class PrivateTag < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  include ElasticSearch::AutomaticPeopleReindexing

  #################
  ### CALLBACKS ###
  #################

  before_destroy :ensure_it_doesnt_have_members

  #################
  ### RELATIONS ###
  #################

  # FIXME: Incompatible with person's HABTM
  # default_scope { order('name ASC') }
  scope :by_usage, -> do
    select("private_tags.id, private_tags.name, private_tags.color, count(people_private_tags.private_tag_id) AS tags_count")
    .joins(:people)
    .group("people_private_tags.private_tag_id, private_tags.id, private_tags.name")
    .order("tags_count DESC")
  end

  # TODO Raises deprecations warnings
  acts_as_tree

  has_and_belongs_to_many :people,
                          -> { uniq },
                          after_add: :update_elasticsearch_index,
                          after_remove: :update_elasticsearch_index
  has_many :subscription_values,
           -> { order('position ASC') }

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :parent_id
  validate :cannot_be_its_own_parent

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255
  validates_format_of :color,
    with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/,
    allow_blank: true


  ########################
  ### INSTANCE METHODS ###
  ########################

  def cannot_be_its_own_parent
    if parent == self
      errors.add(:parent, I18n.t('tag.errors.cannot_be_its_own_parent'))
      false
    end
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options || {})
    h[:parent_name] = parent.try(:name)
    h[:members_count] = people.count
    h
  end

  def ensure_it_doesnt_have_members
    if self.people.count > 0
      errors.add(:base,
                 I18n.t('tag.errors.cannot_destroy_tag_if_it_has_members'))
      false
    end
  end

end
