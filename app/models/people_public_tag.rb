# == Schema Information
#
# Table name: people_public_tags
#
#  person_id     :integer
#  public_tag_id :integer
#

class PeoplePublicTag < ApplicationRecord
  #################
  ### RELATIONS ###
  #################

  belongs_to :person
  belongs_to :public_tag
end
