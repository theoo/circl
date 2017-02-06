# == Schema Information
#
# Table name: subscription_values
#
#  id                  :integer          not null, primary key
#  subscription_id     :integer          not null
#  invoice_template_id :integer          not null
#  private_tag_id      :integer
#  value_in_cents      :integer          default(0)
#  value_currency      :string(255)      default("CHF")
#  position            :integer          not null
#

class SubscriptionValue < ApplicationRecord

  ################
  ### CALLBACKS ##
  ################

  before_validation do
    set_template_if_none_given
    set_position_if_none_given
  end

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  extend  MoneyComposer

  #################
  ### RELATIONS ###
  #################

  belongs_to :subscription
  belongs_to :invoice_template
  belongs_to :private_tag

  ###################
  ### VALIDATIONS ###
  ###################

  validates :subscription_id, presence: true, numericality: true
  validates :invoice_template_id, presence: true, numericality: true
  validates :private_tag_id, allow_blank: true, allow_nil: true, numericality: true
  validates :value_in_cents, presence: true, numericality: true
  validates :value_currency, presence: true
  validates :position, presence: true, numericality: true

  ########################
  ### INSTANCE METHODS ###
  ########################

  # Money
  money :value

  private

  def set_template_if_none_given
    self.invoice_template = InvoiceTemplate.first unless invoice_template
  end

  def set_position_if_none_given
    pos = self.position
    unless position
      if self.subscription
        if self.subscription.values.count > 0
          pos = self.subscription.values.last.position + 1
        end
      end
      self.position = pos ? pos : 0
    end
  end

end
