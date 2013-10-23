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
# Table name: affairs
#
# *id*::             <tt>integer, not null, primary key</tt>
# *owner_id*::       <tt>integer, not null</tt>
# *buyer_id*::       <tt>integer, not null</tt>
# *receiver_id*::    <tt>integer, not null</tt>
# *title*::          <tt>string(255), default(""), not null</tt>
# *description*::    <tt>text, default("")</tt>
# *value_in_cents*:: <tt>integer, default(0), not null</tt>
# *value_currency*:: <tt>string(255), default("CHF"), not null</tt>
# *created_at*::     <tt>datetime</tt>
# *updated_at*::     <tt>datetime</tt>
#--
# == Schema Information End
#++

class Affair < ActiveRecord::Base
  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include StatusExtention
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  #################
  ### CALLBACKS ###
  #################

  after_save :update_elasticsearch
  before_save :compute_value, :update_statuses
  before_validation  :ensure_buyer_and_receiver_person_exists
  before_destroy :do_not_destroy_if_has_invoices
  before_destroy { subscriptions.clear }

  #################
  ### RELATIONS ###
  #################

  # Relations
  belongs_to  :owner, :class_name => 'Person', :foreign_key => 'owner_id'
  belongs_to  :buyer, :class_name => 'Person', :foreign_key => 'buyer_id'
  belongs_to  :receiver, :class_name => 'Person', :foreign_key => 'receiver_id'

  has_many    :invoices, :dependent => :destroy
  has_many    :receipts, :through => :invoices, :uniq => true

  has_many    :tasks, :dependent => :destroy
  monitored_habtm :subscriptions,
                  :after_add    => :update_on_subscription_habtm_alteration,
                  :after_remove => :update_on_subscription_habtm_alteration
  has_many :affairs_subscriptions # for permissions
  # has_and_belongs_to_many :products

  # Money
  money :value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :owner_id, :buyer_id, :receiver_id, :value_in_cents, :value_currency

  # Validate fields of type 'string' length
  validates_length_of :title, :maximum => 255

  # Validate fields of type 'text' length
  validates_length_of :description, :maximum => 65536

  ########################
  #### CLASS METHODS #####
  ########################

  # Returns the list of available statuses as an array.
  # Watch the sources to read available statuses.
  def self.available_statuses
    [
                      # under bit weight 256 (bits 0-7),
                      # invoice is not (fully) paid
     :open,           # 0
     :underpaid,      # 1
     :partially_paid, # 2
     nil,             # 3
     nil,             # 4
     nil,             # 5
     nil,             # 6
     :cancelled,      # 7

                      # starting from 256 (bit 8-15),
                      # invoice is paid
     :paid,           # 8
     :overpaid,       # 9
     nil,             # 10
     nil,             # 11
     nil,             # 12
     nil,             # 13
     nil,             # 14
     :offered         # 15
    ]
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)
    h[:owner_name]     = owner.try(:name)
    h[:buyer_name]     = buyer.try(:name)
    h[:receiver_name]  = receiver.try(:name)
    h[:invoices_count] = invoices.count
    h[:invoices_value] = invoices_value.to_f
    h[:receipts_count] = receipts.count
    h[:receipts_value] = receipts_value.to_f
    h[:value]          = value.try(:to_f)
    h[:statuses]       = get_statuses.map{|s| I18n.t("affair.views.statuses." + s.to_s)}.join(", ")
    h
  end

  def invoices_value
    invoices.map(&:value).sum.to_money
  end

  def receipts_value
    receipts.map(&:value).sum.to_money
  end

  def balance_value
    receipts_value - invoices_value
  end

  def overpaid_value
    (balance_value > 0) ? balance_value : 0
  end

  # Workflows and statuses

  # Returns true if all invoices are open in this affair.
  def open?
    invoices.inject(false) { |sum, i| sum | i.has_status?(:open) }
  end

  # Returns true if invoices are partially paid in this affair.
  def partially_paid?
    if open?
      return invoices.inject(false) { |sum, i| sum | i.has_status?(:paid) }
    end
    false
  end

  # Return true if every single invoice has been paid.
  # If the sum of receipts is greater than the sum of invoices, it
  # doesn't means every single invoice has been paid.
  def paid?
    invoices.inject(true) { |sum, i| sum & i.has_status?(:paid) }
  end

  # Returns true if at leaset one invoice is overpaid in this affair.
  def overpaid?
    invoices.inject(false) { |sum, i| sum | i.has_status?(:overpaid) }
  end

  # Returns true if at least one invoice is underpaid in this affair.
  def underpaid?
    invoices.inject(false) { |sum, i| sum | i.has_status?(:underpaid) }
  end

  # Returns true if all invoices are set to cancelled.
  def cancelled?
    invoices.inject(true) { |sum, i| sum & i.has_status?(:cancelled) }
  end

  # Returns true if all invoices are set to offered.
  def offered?
    invoices.inject(true) { |sum, i| sum & i.has_status?(:offered) }
  end

  private

  # Buffer method used to update value and statuses information after habtm relationship
  # alteration.
  def update_on_subscription_habtm_alteration(record = nil)
    self.update_attribute(:value, compute_value)
    self.update_attribute(:status, update_statuses)
  end

  # It will set this affair's value to the computed value of all provisions and
  # returns its value.
  def compute_value
    self.value = compute_subscriptions_total
    # self.value += compute_tasks_total
    self.value
  end

  # Update this affair's statuses by comparing affair's value, its invoices and receipts
  # and return its statuses.
  def update_statuses
    statuses = []
    statuses << :open if open?
    statuses << :underpaid if underpaid?
    statuses << :partially_paid if partially_paid?
    statuses << :cancelled if cancelled?

    # TODO How an invoice could be paid and open in the same time ?
    statuses << :paid if paid?
    statuses << :overpaid if overpaid?
    statuses << :offered if offered?

    self.reset_statuses(statuses)
    statuses
  end

  def compute_subscriptions_total
    # Sum only leaves of a subscription tree (the last child)
    leaves = find_children(subscriptions)
    leaves.map{|l| l.value_for(owner)}.sum.to_money
  end

  def find_children(subscriptions)
    subs = []
    subscriptions.each do |s|
      if s.children.empty?
        subs << s
      else
        subs << find_children(s.children)
      end
    end
    subs.flatten.uniq
  end

  def compute_tasks_total
    tasks.map(&:value).sum.to_money
  end

  def ensure_buyer_and_receiver_person_exists
    self.receiver = self.owner unless self.receiver
    self.buyer = self.owner unless self.buyer
  end

  def update_elasticsearch
    # It may have some custom search attributes which
    # depends on this affair through it's relations.
    # so update relations' indices no mater what changes
    unless tracked_changes.empty?
      # update current relations' indices
      owner.update_index
      if buyer != owner
        buyer.update_index
        receiver.update_index if buyer != receiver
      end

      # and former relations' indices
      if tracked_changes.keys.index('buyer_id')
        # 0:original, 1:new value == self.buyer_id
        buyer_id = tracked_changes['buyer_id'][0]
        if Person.exists?(buyer_id) # in case former person doesn't exists
          p = Person.find(buyer_id)
          p.update_index
        end
      end

      if tracked_changes.keys.index('receiver_id')
        # 0:original, 1:new value == self.receiver_id
        receiver_id = tracked_changes['receiver_id'][0]
        if Person.exists?(receiver_id)
          p = Person.find(receiver_id)
          p.update_index
        end
      end
    end
    true
  end

  def do_not_destroy_if_has_invoices
    unless invoices.empty?
      errors.add(:base,
                 I18n.t('affair.errors.cant_delete_affair_who_has_invoices'))
      false
    end
  end

end
