class AffairsSubscription < ApplicationRecord

  #################
  ### RELATIONS ###
  #################

  belongs_to :affair
  belongs_to :subscription


  ###################
  ### VALIDATIONS ###
  ###################

  validates_uniqueness_of :subscription_id, scope: :affair_id
end
