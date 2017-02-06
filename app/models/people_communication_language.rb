# == Schema Information
#
# Table name: people_communication_languages
#
#  person_id   :integer
#  language_id :integer
#

class PeopleCommunicationLanguage < ApplicationRecord
  #################
  ### RELATIONS ###
  #################

  belongs_to :person
  belongs_to :language
end
