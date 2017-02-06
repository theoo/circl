# == Schema Information
#
# Table name: people_private_tags
#
#  person_id      :integer
#  private_tag_id :integer
#

class PeoplePrivateTag < ApplicationRecord
  #################
  ### RELATIONS ###
  #################

  belongs_to :person
  belongs_to :private_tag
end
