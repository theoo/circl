# == Schema Information
#
# Table name: people_roles
#
#  person_id :integer
#  role_id   :integer
#

class PeopleRole < ApplicationRecord
  #################
  ### RELATIONS ###
  #################

  belongs_to :person
  belongs_to :role
end
