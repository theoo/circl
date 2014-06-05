class AffairsCondition < ActiveRecord::Base

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

  has_many :affairs

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates_presence_of :description

  ########################
  ### INSTANCE METHODS ###
  ########################

end
