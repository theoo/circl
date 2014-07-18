class AffairsCondition < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker

  #####################
  ### MISCEALLENOUS ###
  #####################

  #################
  ### CALLBACKS ###
  #################

  #################
  ### RELATIONS ###
  #################

  has_many :affairs, foreign_key: :condition_id

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates_presence_of :description

  ########################
  ### INSTANCE METHODS ###
  ########################

  def as_json(options = nil)
    h = super(options)
    h[:affairs_count] = affairs.count
    h
  end

end
