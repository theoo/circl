# == Schema Information
#
# Table name: jobs
#
#  id          :integer          not null, primary key
#  name        :string(255)      default("")
#  description :text             default("")
#

class Job < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### RELATIONS ###
  #################
  has_many  :people


  ###################
  ### VALIDATIONS ###
  ###################
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name,
                      with: /\A[^,]+\z/i,
                      allow_blank: true,
                      message: :cannot_contain_comma
                      # message: I18n.t("job.errors.cannot_contain_comma")

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536


  ########################
  ### INSTANCE METHODS ###
  ########################
  def as_json(options = nil)
    h = super(options || {})
    h[:members_count] = people.count
    h
  end

end
