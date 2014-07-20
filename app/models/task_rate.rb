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

class TaskRate < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  include ElasticSearch::AutomaticPeopleReindexing
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  before_destroy :prevent_if_client_present

  #################
  ### RELATIONS ###
  #################

  has_many :people, dependent: :nullify

  # Money
  money :value

  scope :actives,  -> { where(archive: false)}
  scope :archived, -> { where(archive: true)}

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates :value, presence: true,
                    numericality: {greater_than: 0,
                                      less_than_or_equal: 99999999.99 } # BVR limit

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536

  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)
    h[:value]        = value.to_f
    h[:people_count] = people.count
    h[:errors]       = errors
    h
  end

  private

  def prevent_if_client_present
    if people.count > 0
      errors.add(:base, I18n.t('task_rate.errors.cannot_destroy_if_client_present'))
      return false
    end
  end

end
