class Comment < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### RELATIONS ###
  #################

  belongs_to  :person
  belongs_to  :resource, polymorphic: true


  ###################
  ### VALIDATIONS ###
  ###################
  validates_presence_of :title, :description, :resource_type, :resource_id
  validates_with Validators::PointsToModel, attr: :resource_type

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536

  scope :open_comments, -> { where(is_closed: false) }


  ########################
  ### INSTANCE METHODS ###
  ########################

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:person_name] = person.try(:name)
    h[:resource_name] = resource.try(:name)
    h[:errors] = errors

    h
  end

end
