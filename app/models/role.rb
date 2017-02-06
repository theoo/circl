# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)      default("")
#  description :text             default("")
#  created_at  :datetime
#  updated_at  :datetime
#

class Role < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### CALLBACKS ###
  #################

  before_destroy :check_for_associated_people

  #################
  ### RELATIONS ###
  #################

  has_many  :permissions, dependent: :destroy

  has_many  :people_roles # for permissions
  has_many  :people,
            -> { distinct },
            class_name: 'Person',
            through: :people_roles,
            after_add: :update_elasticsearch_index,
            after_remove: :update_elasticsearch_index

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_uniqueness_of :name

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536


  ########################
  ### INSTANCE METHODS ###
  ########################

  def set_all_permissions!
    # reset permissions beforhands to ensure role have full access
    reset_permissions!

    # set all available permissions to this role
    perms = Permission.get_available_permissions.each do |p|
      attrs = p.attributes
      attrs.delete("id")
      attrs["role_id"] = self.id
      Permission.create(attrs)
    end
  end

  def reset_permissions!
    permissions.each{|p| p.destroy}
    permissions = []
    # or this self requires a reload
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:permissions_count] = permissions.count
    h[:members_count]     = people.count
    h[:errors]            = errors

    h
  end


  protected

  # on destroy, abort if there people associated to role
  def check_for_associated_people
    unless people.empty?
      errors.add(:base, I18n.t('role.errors.cant_delete_if_in_use'))
      false
    end
  end

end
