class AffairsStakeholder < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  #####################
  ### MISCEALLENOUS ###
  #####################

  #################
  ### CALLBACKS ###
  #################

  #################
  ### RELATIONS ###
  #################

  default_scope { order(:id) }

  belongs_to :person
  belongs_to :affair

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title

  ########################
  ### INSTANCE METHODS ###
  ########################

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)
    h[:person_name]  = person.try :name
    # h[:affair_title] = affair.try :title
    h
  end

end
