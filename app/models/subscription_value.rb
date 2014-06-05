=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

# == Schema Information
#
# Table name: subscription_values
#
# *id*::                  <tt>integer, not null, primary key</tt>
# *subscription_id*::     <tt>integer, not null</tt>
# *invoice_template_id*:: <tt>integer, not null</tt>
# *private_tag_id*::      <tt>integer</tt>
# *value_in_cents*::      <tt>integer, default(0)</tt>
# *value_currency*::      <tt>string(255), default("CHF")</tt>
# *position*::            <tt>integer, not null</tt>
#--
# == Schema Information End
#++

class SubscriptionValue < ActiveRecord::Base

  ################
  ### CALLBACKS ##
  ################

  before_validation :set_position_if_none_given
  # before_destroy :ensure_is_destroyable

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
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
