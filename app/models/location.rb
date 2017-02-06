# == Schema Information
#
# Table name: locations
#
#  id                 :integer          not null, primary key
#  parent_id          :integer
#  name               :string(255)      default("")
#  iso_code_a2        :string(255)      default("")
#  iso_code_a3        :string(255)      default("")
#  iso_code_num       :string(255)      default("")
#  postal_code_prefix :string(255)      default("")
#  phone_prefix       :string(255)      default("")
#

class Location < ApplicationRecord

  #################
  ### CALLBACKS ###
  #################

  before_destroy :ensure_it_has_no_relations

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

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

  def as_json(options = {})
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
