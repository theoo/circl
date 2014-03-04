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
  before_save :update_value, :if => 'value_in_cents.blank?'
  before_save :compute_value_without_taxes, :if => 'custom_value_with_taxes'
  before_save :update_statuses
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
  belongs_to  :seller, :class_name => 'Person', :foreign_key => 'seller_id'

  has_one     :parent, :class_name => 'Affair', :primary_key => 'parent_id', :foreign_key => 'id'
  has_many    :children, :class_name => 'Affair', :foreign_key => 'parent_id'

  has_many    :invoices, :dependent => :destroy
  has_many    :receipts, :through => :invoices, :uniq => true

  has_many    :extras, :dependent => :destroy
                       #:after_add    => :update_on_prestation_alteration,
                       #:after_remove => :update_on_prestation_alteration

  has_many    :tasks, :dependent => :destroy
                      #:after_add    => :update_on_prestation_alteration,
                      #:after_remove => :update_on_prestation_alteration

  has_many    :product_items, :class_name => 'AffairsProductsProgram',
                              :dependent => :destroy,
                              :order => :position
                              #:after_add    => :update_on_prestation_alteration,
                              #:after_remove => :update_on_prestation_alteration

  has_many    :products, :through => :product_items
  has_many    :programs, :through => :product_items
  # has_many    :product_variants, :through => :products

  monitored_habtm :subscriptions,
                  :after_add    => :update_on_prestation_alteration,
                  :after_remove => :update_on_prestation_alteration
  has_many :affairs_subscriptions # for permissions

  # Money
  money :value

  scope :open_affairs, Proc.new {
    mask = Affair.statuses_value_for(:open)
    where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
  }

  # Used to calculate value from value with taxes
  attr_accessor :custom_value_with_taxes


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :owner_id, :buyer_id, :receiver_id, :value_in_cents, :value_currency

  # Validate fields of type 'string' length
  validates_length_of :title, :maximum => 255

  # Validate fields of type 'text' length
  validates_length_of :description, :maximum => 65536
  validate :vat_calculation_availability, :if => 'custom_value_with_taxes'

  ########################
  #### CLASS METHODS #####
  ########################

  # Returns the list of available statuses as an array.
  # Watch the sources to read available statuses.
  def self.available_statuses
    [
                      # under bit weight 256 (bits 0-7),
                      # invoices are not (fully) paid
     :open,           # 0
     :underpaid,      # 1
     :partially_paid, # 2
     :to_be_billed,   # 3
     nil,             # 4
     nil,             # 5
     nil,             # 6
     :cancelled,      # 7

                      # starting from 256 (bit 8-15),
                      # invoices are paid
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
    h[:parent_title]                       = parent.try(:title)
    h[:owner_name]                         = owner.try(:name)
    h[:owner_address]                      = owner.try(:address_for_bvr)
    h[:buyer_name]                         = buyer.try(:name)
    h[:buyer_address]                      = buyer.try(:address_for_bvr)
    h[:seller_name]                        = seller.try(:name)
    h[:receiver_name]                      = receiver.try(:name)
    h[:receiver_address]                   = receiver.try(:address_for_bvr)
    h[:invoices_count]                     = invoices.count
    h[:invoices_value]                     = invoices_value.to_f
    h[:invoices_value_currency]            = invoices_value.currency.try(:iso_code)
    h[:receipts_count]                     = receipts.count
    h[:receipts_value]                     = receipts_value.to_f
    h[:receipts_value_currency]            = receipts_value.currency.try(:iso_code)
    h[:subscriptions_count]                = subscriptions.count
    h[:subscriptions_value]                = subscriptions_value.to_f
    h[:subscriptions_value_currency]       = subscriptions_value.currency.try(:iso_code)
    h[:tasks_count]                        = tasks.count
    h[:tasks_value]                        = tasks_value.to_f
    h[:tasks_value_currency]               = tasks_value.currency.try(:iso_code)
    h[:products_count]                     = product_items.count
    h[:products_value]                     = product_items_value.to_f
    h[:products_value_currency]            = product_items_value.currency.try(:iso_code)
    h[:extras_count]                       = extras.count
    h[:extras_value]                       = extras_value.to_f
    h[:extras_value_currency]              = extras_value.currency.try(:iso_code)
    h[:value]                              = value.try(:to_f)
    h[:value_currency]                     = value.currency.try(:iso_code)
    h[:computed_value]                     = compute_value.try(:to_f)
    h[:computed_value_currency]            = compute_value.currency.try(:iso_code)
    h[:computed_value_with_taxes]          = compute_value_with_taxes.try(:to_f)
    h[:computed_value_with_taxes_currency] = compute_value_with_taxes.currency.try(:iso_code)
    h[:arts_count]                         = product_items.each_with_object([]){|i,a| a << i if i.variant.art > 0}.size
    h[:arts_value]                         = arts_value.try(:to_f)
    h[:arts_value_currency]                = arts_value.currency.try(:iso_code)
    h[:vat_count]                          = extras.each_with_object([]){|i,a| a << i if i.vat_percentage != ApplicationSetting.value("service_vat_rate").to_f}.size + 1
    h[:vat_value]                          = vat_value.try(:to_f)
    h[:vat_value_currency]                 = vat_value.currency.try(:iso_code)
    h[:statuses]                           = translated_statuses
    h
  end

  def translated_statuses
    get_statuses.map{|s| I18n.t("affair.views.statuses." + s.to_s)}.join(", ")
  end

  def invoices_value
    invoices.map(&:value).sum.to_money(value_currency)
  end

  def receipts_value
    receipts.map(&:value).sum.to_money(value_currency)
  end

  def subscriptions_value
    # Sum only leaves of a subscription tree (the last child)
    leaves = find_children(subscriptions)
    leaves.map{|l| l.value_for(owner)}.sum.to_money(value_currency)
  end

  def tasks_value
    tasks.map(&:value).sum.to_money(value_currency)
  end

  def product_items_value
    product_items.map(&:value).sum.to_money(value_currency)
  end

  def extras_value
    extras.map(&:value).sum.to_money(value_currency)
  end

  def balance_value
    receipts_value - invoices_value
  end

  def overpaid_value
    (balance_value > 0) ? balance_value : 0.to_money
  end

  def arts_value
    product_items.map{|i| i.variant.art * i.quantity}.sum.to_money(value_currency)
  end

  def vat_value(forced_value = self.value)
    # Variable VAT, extract extras with different vat rate
    extra_with_different_vat_rate = extras.each_with_object([]) do |i,a|
      a << i if i.vat_percentage != ApplicationSetting.value("service_vat_rate").to_f
    end

    extras_diff_value = extra_with_different_vat_rate.map(&:value).sum.to_money(value_currency)
    extras_diff_vat = extra_with_different_vat_rate.map(&:vat).sum.to_money(value_currency)

    service_value = forced_value - extras_diff_value
    sum = service_value / 100.0 * ApplicationSetting.value("service_vat_rate").to_f
    sum += extras_diff_vat

    sum
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
    return false if invoices.count == 0
    invoices.inject(true) { |sum, i| sum & i.has_status?(:paid) }
  end

  # Returns true if at leaset one invoice is overpaid in this affair.
  def overpaid?
    return false if invoices.count == 0
    invoices.inject(false) { |sum, i| sum | i.has_status?(:overpaid) }
  end

  # Returns true if at least one invoice is underpaid in this affair.
  def underpaid?
    return false if invoices.count == 0
    invoices.inject(false) { |sum, i| sum | i.has_status?(:underpaid) }
  end

  # Returns true if all invoices are set to cancelled.
  def cancelled?
    return false if invoices.count == 0
    invoices.inject(true) { |sum, i| sum & i.has_status?(:cancelled) }
  end

  # Returns true if all invoices are set to offered.
  def offered?
    return false if invoices.count == 0
    invoices.inject(true) { |sum, i| sum & i.has_status?(:offered) }
  end

  def to_be_billed?
    invoices_value < value
  end

  private

  # Buffer method used to update value and statuses information after habtm relationship
  # alteration.
  def update_on_prestation_alteration(record = nil)
    self.update_attribute(:value, compute_value)
    self.update_attribute(:status, update_statuses)
  end

  # It will set this affair's value to the computed value of all provisions and
  # returns its value.
  def compute_value
    val = subscriptions_value
    val += tasks_value
    val += product_items_value
    val += arts_value
    val += extras_value
    val.to_money(value_currency)
  end

  def compute_value_with_taxes
    val = compute_value
    taxes = vat_value(val)
    val + taxes
  end

  def update_value
    self.value = compute_value
  end

  def compute_value_without_taxes
    self.value = reverse_vat_value(value)
  end

  def reverse_vat_value(value_with_taxes)
    value_with_taxes / ( 1 + (ApplicationSetting.value("service_vat_rate").to_f / 100) )
  end

  def vat_calculation_availability
    extras.each do |i|
      if i.vat_percentage != ApplicationSetting.value("service_vat_rate").to_f
        errors.add(:base,
           I18n.t('affair.errors.unable_to_compute_value_without_taxes_if_extras_have_different_vat_values'))
        return false
      end
    end
  end

  # Update this affair's statuses by comparing affair's value, its invoices and receipts
  # and return its statuses.
  def update_statuses
    statuses = []
    statuses << :open if open?
    statuses << :underpaid if underpaid?
    statuses << :partially_paid if partially_paid?
    statuses << :to_be_billed if to_be_billed?
    statuses << :cancelled if cancelled?

    # TODO How an invoice could be paid and open in the same time ?
    statuses << :paid if paid?
    statuses << :overpaid if overpaid?
    statuses << :offered if offered?

    self.reset_statuses(statuses)
    statuses
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
