# == Schema Information
#
# Table name: query_presets
#
#  id    :integer          not null, primary key
#  name  :string(255)      default("")
#  query :text             default("")
#

class QueryPreset < ApplicationRecord

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

  before_save do
    if self_is_first_preset? and not self.query["search_string"].blank?
      errors.add :base, I18n.t("search_attribute.errors.default_query_preset_cannot_contain_a_query_string")
      false
    end
  end

  before_destroy do
    if self_is_first_preset?
      errors.add :base, I18n.t("search_attribute.errors.unable_to_destroy_default_query_preset")
      false
    end
  end

  def self_is_first_preset?
    self == QueryPreset.reorder(:id).first
  end

  private

  def set_default_query
    self.query ||= { selected_attributes: [], attributes_order: [] }
  end

end
