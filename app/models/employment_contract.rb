class EmploymentContract < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker

  #################
  ### CALLBACKS ###
  #################

  before_destroy :check_interval_is_in_past_or_future
  after_commit :update_people_in_search_engine

  #################
  ### RELATIONS ###
  #################

  belongs_to :person


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :percentage, :interval_starts_on, :interval_ends_on, :person_id

  validates_numericality_of :percentage,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100,
                            only_integer: false

  validates_with Validators::Interval
  validates_with Validators::Date, attribute: :interval_starts_on
  validates_with Validators::Date, attribute: :interval_ends_on

  validate :person_exists

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536


  ########################
  ### INSTANCE METHODS ###
  ########################

  # returns true if today is included in interval
  def is_running?
    today = Date.today
    today >= interval_starts_on && today <= interval_ends_on
  end

  protected

  # validation method
  def person_exists
    if person_id # person_id should exist, check validates_pesence_of
      unless Person.exists?(person_id)
        errors.add(:person_id,
                   I18n.t('employment_contract.errors.person_does_not_exist'))
      end
    end
  end

  # callback
  # if today is in range of interval abort
  def check_interval_is_in_past_or_future
    today = Date.today
    unless today > interval_ends_on || today < interval_starts_on
      errors.add(:base,
                 I18n.t('employment_contract.errors.cant_delete_contract_if_current'))
      false
    end
  end

  private

  # FIXME Why this ?
  def update_people_in_search_engine
    person.update_search_engine unless self.changes.empty?
  end

end
