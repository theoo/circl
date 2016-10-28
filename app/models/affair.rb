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

class Affair < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  # Monetize deprecation warning
  require 'monetize/core_extensions'

  include StatusConcern
  include VatConcern
  include SearchEngineConcern
  extend  MoneyComposer

  # TODO: Move this to jsbuilder
  class InvoiceHelper
    include ActionView::Helpers::DateHelper
  end

  def helper
    @h || InvoiceHelper.new
  end

  #################
  ### CALLBACKS ###
  #################

  after_save do
    update_people_in_search_engine
    cancel_open_invoices if unbillable or archive

    true
  end

  before_save do
    self.unbillable = true if archive
    self.touch(:sold_at) if not estimate and estimate_was

    update_value if value_in_cents.blank?
    update_vat if vat_in_cents.blank?
    set_vat_percentage if vat_percentage.blank?
    compute_value_without_taxes if custom_value_with_taxes
    update_statuses

    true
  end

  before_validation  :ensure_buyer_and_receiver_person_exists
  before_destroy :do_not_destroy_if_has_invoices
  before_destroy :do_not_destroy_if_has_children
  before_destroy { subscriptions.clear }

  #################
  ### RELATIONS ###
  #################

  # Relations
  belongs_to  :owner,
              class_name: 'Person',
              foreign_key: 'owner_id'

  belongs_to  :buyer,
              class_name: 'Person',
              foreign_key: 'buyer_id'

  belongs_to  :receiver,
              class_name: 'Person',
              foreign_key: 'receiver_id'
  belongs_to  :seller,
              class_name: 'Person',
              foreign_key: 'seller_id'

  belongs_to  :condition,
              class_name: 'AffairsCondition'

  has_one     :parent,
              class_name: 'Affair',
              primary_key: 'parent_id',
              foreign_key: 'id'

  has_many    :children,
              class_name: 'Affair',
              foreign_key: 'parent_id'

  has_many    :invoices,
              dependent: :destroy

  has_many    :receipts,
              -> { distinct },
              through: :invoices

  has_many    :extras,
              -> { order(:position) },
              dependent: :destroy,
              after_add: :update_on_prestation_alteration,
              after_remove: :update_on_prestation_alteration

  has_many    :tasks,
              -> { order('start_date ASC') },
              dependent: :destroy,
              after_add: :update_on_prestation_alteration,
              after_remove: :update_on_prestation_alteration

  has_many    :product_items,
              -> { order(:position) },
              dependent: :destroy,
              after_add: :update_on_prestation_alteration,
              after_remove: :update_on_prestation_alteration

  has_many    :products,
              through: :product_items
  has_many    :programs,
              through: :product_items

  has_many    :product_categories,
              -> { order(:position).uniq },
              class_name: "AffairsProductsCategory",
              dependent: :destroy

  has_many    :affairs_stakeholders

  has_many    :stakeholders,
              through: :affairs_stakeholders,
              source: :person

  has_many    :affairs_subscriptions # for permissions

  # monitored_habtm :subscriptions,
  has_and_belongs_to_many :subscriptions,
              after_add: :update_on_prestation_alteration,
              after_remove: :update_on_prestation_alteration

  # Money
  money :value
  money :vat

  # FIXME open is a private method from ActiveRecord, do not override it (change name)
  scope :open, -> {
    mask = Affair.statuses_value_for(:to_be_billed)
    where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
  }

  scope :alive, -> { where(archive: false) }
  scope :archived, -> { where(archive: true) }

  scope :estimates,  -> { where estimate: true }
  scope :effectives, -> { where estimate: false}

  # Used to calculate value from value with taxes
  attr_accessor :custom_value_with_taxes
  attr_accessor :template

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :owner_id, :buyer_id, :receiver_id, :value_in_cents, :value_currency

  validates :alias_name,
    format: { with: /\A[a-zA-Z\-_\d]+\z/, message: I18n.t("person.errors.only_letters")},
    length: { maximum: 25 },
    unless: 'alias_name.blank?'

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :description, maximum: 65536
  validates_length_of :footer, maximum: 65536
  validates_length_of :notes, maximum: 65536
  validates_length_of :execution_notes, maximum: 65536
  validate :vat_calculation_availability, if: 'custom_value_with_taxes'
  validate :parent_id_is_not_self, if: 'parent_id'
  validate :prevent_title_change, if: 'title_changed?'

  ########################
  #### CLASS METHODS #####
  ########################

  class << self
    # Returns the list of available statuses as an array. Order in array matter.
    # Watch the sources to read available statuses.
    def available_statuses
      # i18n-tasks-use I18n.t("affair.views.statuses.open")
      # i18n-tasks-use I18n.t("affair.views.statuses.underpaid")
      # i18n-tasks-use I18n.t("affair.views.statuses.partially_paid")
      # i18n-tasks-use I18n.t("affair.views.statuses.to_be_billed")
      # i18n-tasks-use I18n.t("affair.views.statuses.cancelled")
      # i18n-tasks-use I18n.t("affair.views.statuses.paid")
      # i18n-tasks-use I18n.t("affair.views.statuses.overpaid")
      # i18n-tasks-use I18n.t("affair.views.statuses.unbillable")
      # i18n-tasks-use I18n.t("affair.views.statuses.offered")

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
       :cancelled,      # 7 user defined

                        # starting from 256 (bit 8-15),
                        # invoices are paid
       :paid,           # 8
       :overpaid,       # 9
       :unbillable,     # 10
       :archived,       # 11
       nil,             # 12
       nil,             # 13
       nil,             # 14
       :offered         # 15 user defined
      ]
    end

  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)
    h[:created_at]                         = created_at.to_date # Override datetime
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
    h[:invoices_value_with_taxes]          = invoices_value_with_taxes.to_f
    h[:invoices_value_with_taxes_currency] = invoices_value_with_taxes.currency.try(:iso_code)
    h[:receipts_count]                     = receipts.count
    h[:receipts_value]                     = receipts_value.to_f
    h[:receipts_value_currency]            = receipts_value.currency.try(:iso_code)
    h[:subscriptions_count]                = subscriptions.count
    h[:subscriptions_value]                = subscriptions_value.to_f
    h[:subscriptions_value_currency]       = subscriptions_value.currency.try(:iso_code)
    h[:tasks_count]                        = tasks.count
    h[:tasks_value]                        = tasks_value.to_f
    h[:tasks_value_currency]               = tasks_value.currency.try(:iso_code)
    h[:tasks_duration_translation]         = helper.distance_of_time(tasks_duration.minutes)
    h[:products_count]                     = product_items.count
    h[:products_value]                     = product_items_value.to_f
    h[:products_value_currency]            = product_items_value.currency.try(:iso_code)
    h[:extras_count]                       = extras.count
    h[:extras_value]                       = extras_value.to_f
    h[:extras_value_currency]              = extras_value.currency.try(:iso_code)
    h[:value]                              = value.try(:to_f)
    h[:value_currency]                     = value.currency.try(:iso_code)
    h[:value_with_taxes]                   = value_with_taxes.try(:to_f)
    h[:value_with_taxes_currency]          = value_with_taxes.currency.try(:iso_code)
    h[:computed_value]                     = compute_value.try(:to_f)
    h[:computed_value_currency]            = compute_value.currency.try(:iso_code)
    h[:computed_value_with_taxes]          = compute_value_with_taxes.try(:to_f)
    h[:computed_value_with_taxes_currency] = compute_value_with_taxes.currency.try(:iso_code)
    h[:arts_count]                         = arts_count
    h[:arts_value]                         = arts_value.try(:to_f)
    h[:arts_value_currency]                = arts_value.currency.try(:iso_code)
    h[:vat_count]                          = extras.each_with_object([]){|i,a| a << i if i.vat_percentage != ApplicationSetting.value("service_vat_rate")}.size + 1
    h[:vat]                                = vat.try(:to_f)
    h[:vat_currency]                       = vat.currency.try(:iso_code)
    h[:statuses]                           = translated_statuses
    h[:affairs_stakeholders]               = affairs_stakeholders.as_json
    h[:sold_at]                            = sold_at.try(:to_date)
    h
  end

  def translated_statuses
    get_statuses.map{|s| I18n.t("affair.views.statuses." + s.to_s)}.join(", ")
  end

  def invoices_value
    invoices.billable.map{|i| i.value.try(:to_money, value_currency)}.try(:sum).try(:to_money)
  end

  def invoices_value_with_taxes
    invoices.billable.map{|i| i.value_with_taxes.try(:to_money, value_currency)}.try(:sum).try(:to_money)
  end

  def receipts_value
    receipts.map{ |r| r.value.try(:to_money, value_currency)}.try(:sum).try(:to_money)
  end

  def subscriptions_value
    # Sum only leaves of a subscription tree (the last child)
    leaves = find_children(subscriptions)
    leaves.map{|l| l.value_for(owner).try(:to_money, value_currency)}.try(:sum).try(:to_money)
  end

  def tasks_value
    tasks.map{ |t| t.value.try(:to_money, value_currency)}.try(:sum).try(:to_money)
  end

  def tasks_real_value
    tasks.map{ |t| t.compute_value.try(:to_money, value_currency)}.try(:sum).try(:to_money)
  end

  def tasks_duration
    tasks.map{ |t| t.duration}.sum
  end

  def tasks_bid_value
    tasks_real_value - tasks_value
  end

  def product_items_value(category_name = nil)
    pi = category_name ? product_items_for_category(category_name) : product_items
    pi.map{|p| p.bid_price.to_money(value_currency)}.sum.to_money
  end

  def product_items_real_value(category_name = nil)
    pi = category_name ? product_items_for_category(category_name) : product_items
    pi.map{|p| p.value.to_money(value_currency)}.sum.to_money
  end

  def product_items_bid_value(category_name = nil)
    product_items_real_value(category_name) - product_items_value(category_name)
  end

  def extras_value
    extras.map{|e| e.total_value.to_money(value_currency)}.sum.to_money
  end

  def balance_value
    receipts_value - invoices_value_with_taxes
  end

  def overpaid_value
    (balance_value > 0) ? balance_value : 0.to_money
  end

  def arts_value(category_name = nil)
    pi = category_name ? product_items_for_category(category_name) : product_items
    # See ProductItem#variant definition
    sum = 0.to_money
    pi.each do |i|
      v = i.variant
      sum += v.art.to_money(value_currency) * i.quantity if v
    end
    sum.to_money(value_currency)
  end

  def compute_vat(forced_value = self.value)
    return 0.to_money unless ApplicationSetting.value('use_vat')

    percentage = vat_percentage
    percentage ||= ApplicationSetting.value("service_vat_rate")

    # Variable VAT, extract extras with different vat rate
    extra_with_different_vat_rate = extras.each_with_object([]) do |i,a|
      a << i if i.vat_percentage != percentage
    end

    extras_diff_value = extra_with_different_vat_rate.map(&:value).sum.to_money(value_currency)
    extras_diff_vat = extra_with_different_vat_rate.map(&:vat).sum.to_money(value_currency)

    service_value = forced_value - extras_diff_value
    sum = service_value * (percentage / 100.0)
    sum += extras_diff_vat

    sum
  end

  def arts_count
    product_items.each_with_object([]){|i,a| a << i if i.variant and i.variant.art > 0}.size
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
    val + compute_vat(val)
  end

  def value_with_taxes
    value + vat
  end

  # Workflows and statuses

  #
  # Are all invoices of this affair open ?
  #
  # @return [Boolean] true if all billable invoices are open
  def open?
    invoices.billable.inject(false) { |sum, i| sum | i.has_status?(:open) }
  end

  #
  # Are some invoices of this affair open ?
  #
  # @return [Boolean] true if some billable invoices are open
  def partially_paid?
    if open?
      return invoices.billable.inject(false) { |sum, i| sum | i.has_status?(:paid) }
    end
    false
  end

  #
  # Are all invoices been paid?
  # @note every single invoice has been paid.
  #   If the sum of receipts is greater than the sum of invoices, it doesn't means every single invoice has been paid.
  #   Unbillable invoices (cancelled and offered) are not part of the computation
  #
  # @return [Boolean] true if all billable invoices are paid
  def paid?
    return false if invoices.billable.count == 0
    invoices.billable.inject(true) { |sum, i| sum & i.has_status?(:paid) }
  end


  #
  # Are some invoices overpaid ?
  #
  # @return [Boolean] true if at least one billable invoice is overpaid
  def overpaid?
    return false if invoices.billable.count == 0
    invoices.billable.inject(false) { |sum, i| sum | i.has_status?(:overpaid) }
  end

  #
  # Are some invoices underpaid ?
  #
  # @return [Boolean] true if at least one billable invoice is underpaid
  def underpaid?
    return false if invoices.billable.count == 0
    invoices.billable.inject(false) { |sum, i| sum | i.has_status?(:underpaid) }
  end

  #
  # Are all invoices cancelled ?
  #
  # @return [Boolean] true if all unbillable invoices are set to "cancelled"
  def cancelled?
    return false if invoices.unbillable.count == 0
    invoices.unbillable.inject(true) { |sum, i| sum & i.has_status?(:cancelled) }
  end

  #
  # Are all invoices offered ?
  #
  # @return [Boolean] true if all unbillable invoices are set to "offered"
  def offered?
    return false if invoices.unbillable.count == 0
    invoices.unbillable.inject(true) { |sum, i| sum & i.has_status?(:offered) }
  end

  #
  # Is there something to bill in this affair ?
  #
  # @return [Boolean] true if the #value_with_taxes greater than #invoices_value_with_taxes
  def to_be_billed?
    invoices_value_with_taxes < value_with_taxes
  end

  # Product items sorting
  def product_items_for_category(cat)
    product_items.joins(:category).where("affairs_products_categories.title = ?", cat)
  end

  def product_items_category_value_for(cat)
    sum_product_items_values product_items_for_category(cat)
  end

  def product_items_for_provider(provider)
    product_items.joins(:product).where("products.provider_id = ?", provider)
  end

  def product_items_provider_value_for(provider)
    sum_product_items_values product_items_for_provider(provider)
  end

  def product_items_for_after_sale(after_sale)
    product_items.joins(:product).where("products.after_sale_id = ?", after_sale)
  end

  def product_items_after_sale_value_for(after_sale)
    sum_product_items_values product_items_for_after_sale(after_sale)
  end

  def sum_product_items_values(product_items)
     product_items.map{|p| p.bid_price.to_money(value_currency)}.sum.to_money(value_currency)
  end

  def providers
    p = products.select("DISTINCT(provider_id)").reorder(nil).map(&:provider_id)
    Person.where(id: p)
  end

  def after_sales
    p = products.select("DISTINCT(after_sale_id)").reorder(nil).map(&:after_sale_id)
    Person.where(id: p)
  end

  # This method returns product_items ordered by its current positions and ensure
  # parent/children numerotation is respected.
  # It can take an array of product_items and sort it.
  # TODO lib
  # TODO only one level, no deep recursion yet but would be nice
  def product_items_positions(roots = nil)
    h = {}
    roots ||= product_items.where(parent_id: nil)
    roots.each_with_index do |r, i|
      i += 1
      h[i] = r
      if r.children.size > 0
        r.children.each_with_index{|c, j| h[i + ((j + 1) * 0.01)] = c }
      end
    end
    h
  end

  def reorder_product_items!
    product_items_positions.each do |pos, prod|
      prod.update_attributes(position: pos)
    end
  end

  # Buffer method used to update value and statuses information after habtm relationship
  # alteration.
  # Only update when affair is an estimate
  def update_on_prestation_alteration(record = nil)
    if estimate and ApplicationSetting.value("automatically_calculate_affair_value")
      self.update_attribute(:value, compute_value)
      self.update_attribute(:vat, compute_vat)
      self.update_attribute(:status, update_statuses)
    end
  end

  def update_value!
    update_value
    save!
  end

  def update_vat!
    update_vat
    save!
  end

  # Dates
  %w(created_at updated_at ordered_at confirmed_at delivery_at warranty_begin warranty_end).each do |d|
    define_method("product_items_" + d) do
      dates = product_items.reorder(nil).select("DISTINCT(product_items.#{d})").map{|i| i.send(d)}
      dates.delete(nil)
      dates
    end
  end

  # recusive!
  def parents(s = self)
    parents = [s]
    parents << parents(s.parent) if s.parent
    parents.flatten
  end

  private

  def update_value
    self.value = compute_value
  end

  def update_vat
    self.vat = compute_vat
  end

  def set_vat_percentage
    self.vat_percentage = ApplicationSetting.value("service_vat_rate")
  end

  def compute_value_without_taxes
    self.value = reverse_vat(value)
    update_vat
  end

  def vat_calculation_availability
    extras.each do |i|
      if i.vat_percentage != ApplicationSetting.value("service_vat_rate")
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
    statuses << :cancelled if cancelled?
    statuses << :archived if archive

    if unbillable or value_with_taxes == 0
      statuses << :unbillable
    else
      statuses << :open if open?
      statuses << :underpaid if underpaid?
      statuses << :partially_paid if partially_paid?
      statuses << :to_be_billed if to_be_billed?
    end

    # TODO How an invoice could be paid and open in the same time ?
    # Prevent checkbox on invoices when there is a receipt, add validation
    if offered?
      statuses << :offered
    else
      statuses << :paid if paid?
      statuses << :overpaid if overpaid?
    end

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

  # FIXME Why this ?
  def update_people_in_search_engine
    # It may have some custom search attributes which
    # depends on this affair through it's relations.
    # so update relations' indices no mater what changes
    unless self.changes.empty?
      # update current relations' indices
      owner.update_search_engine
      if buyer != owner
        buyer.update_search_engine
        receiver.update_search_engine if buyer != receiver
      end

      # and former relations' indices
      if self.changes.keys.index('buyer_id')
        # 0:original, 1:new value == self.buyer_id
        buyer_id = self.changes['buyer_id'][0]
        if Person.exists?(buyer_id) # in case former person doesn't exists
          p = Person.find(buyer_id)
          p.update_search_engine
        end
      end

      if self.changes.keys.index('receiver_id')
        # 0:original, 1:new value == self.receiver_id
        receiver_id = self.changes['receiver_id'][0]
        if Person.exists?(receiver_id)
          p = Person.find(receiver_id)
          p.update_search_engine
        end
      end
    end
    true
  end

  def do_not_destroy_if_has_invoices
    unless invoices.empty?
      errors.add(:base, I18n.t('affair.errors.cant_delete_affair_which_has_invoices'))
      false
    end
  end

  def do_not_destroy_if_has_children
    if children.count > 0
      errors.add(:base, I18n.t('affair.errors.can_not_delete_if_has_children'))
      false
    end
  end

  def parent_id_is_not_self
    if id == parent_id
      errors.add(:base, I18n.t('affair.errors.parent_id_cannot_be_self'))
      false
    end
  end

  def cancel_open_invoices
    invoices.open.each{|i| i.update_attributes cancelled: true}
  end

  def prevent_title_change
    if subscriptions.count > 0 and subscriptions.first.title != title
      errors.add(:title, I18n.t('affair.errors.cant_update_title_if_it_has_subscriptions'))
      false
    end
  end

end
