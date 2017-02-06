class Salaries::Salary < ApplicationRecord

  self.table_name = :salaries

  #################
  ### CALLBACKS ###
  #################

  before_create :init_from_reference, if: :has_reference?
  before_create :init_items, unless: :has_reference?
  after_save    :update_tax_data
  before_destroy :prevent_destroy_active_reference, if: :is_reference

  ################
  ### INCLUDES ###
  ################

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### RELATIONS ###
  #################

  # Template
  belongs_to :reference,
             class_name: 'Salaries::Salary',
             foreign_key: :parent_id
  has_many   :children,
             class_name: 'Salaries::Salary',
             foreign_key: :parent_id

  # paperclip
  has_attached_file :pdf

  belongs_to :generic_template

  belongs_to :person
  has_many   :items,
             -> { order(:position) },
             class_name: 'Salaries::Item',
             dependent: :destroy
  has_many   :tax_data,
             -> { order(:position) },
             class_name: 'Salaries::TaxData',
             dependent: :destroy
  has_many   :tasks,
             class_name: '::Task'

  alias_method :template, :generic_template

  # Money
  money :yearly_salary

  # eLohnausweisSSK
  money :cert_food
  money :cert_transport
  money :cert_food
  money :cert_logding
  money :cert_misc_salary_car
  money :cert_misc_salary_other_value
  money :cert_non_periodic_value
  money :cert_capital_value
  money :cert_participation
  money :cert_compentation_admin_members
  money :cert_misc_other_value
  money :cert_avs_ac_aanp
  money :cert_lpp
  money :cert_buy_lpp
  money :cert_is
  money :cert_alloc_traveling
  money :cert_alloc_food
  money :cert_alloc_other_actual_cost_value
  money :cert_alloc_representation
  money :cert_alloc_car
  money :cert_alloc_other_fixed_fees_value
  money :cert_formation

  #############
  ### SCOPE ###
  #############

  scope :reference_salaries, -> { where(is_reference: true) }
  scope :instance_salaries, -> { where(is_reference: false) }
  scope :unpaid_salaries, -> { where(paid: false) }

  #################
  ### Relations ###
  #################

  def selected_tax_data
    tax_data.where(tax_id: items.map{|i| i.taxes}.flatten.uniq)
  end

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :children_count
  validates_presence_of :person_id
  validates_presence_of :generic_template_id
  validates_presence_of :yearly_salary_count, if: :is_reference
  validate :ensure_person_have_required_fields, if: :person
  validate :ensure_interval_dates_are_for_the_same_year, if: [:from, :to]
  validate :ensure_from_date_is_before_to_date, if: [:from, :to]
  validate :ensure_taxes_have_data_for_the_given_interval, if: [:from, :to]
  validates_numericality_of :activity_rate,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100,
                            only_integer: false

  validates_attachment :pdf,
    content_type: { content_type: "application/pdf" }

  ########################
  ### INSTANCE METHODS ###
  ########################

  def taxed_items
    # items.with_category.select{|i| ! i.tax_ids.empty? } # Not AREL
    items.with_category.joins(:taxes).select("DISTINCT salaries_items.*")
  end

  def taxed_items_total
    taxed_items.map(&:value).sum.to_money
  end

  def untaxed_items
    # items.with_category.select{|i| i.tax_ids.empty? } # Not AREL
    items.with_category
      .joins('LEFT OUTER JOIN "salaries_items_taxes" sit ON sit."item_id" = "salaries_items"."id"')
      .joins('LEFT OUTER JOIN "salaries_taxes" st ON st."id" = sit."tax_id"')
      .where('st.id IS NULL')
      .select("DISTINCT salaries_items.*")
  end

  def untaxed_items_total
    untaxed_items.map(&:value).sum.to_money
  end

  def pdf_up_to_date?
    return false
    return false unless pdf_updated_at

    # Check if pdf requires an update because salary is newer
    return false if updated_at > pdf_updated_at.to_datetime

    # Check if pdf requires an update because its template is newer
    generic_template.updated_at < pdf_updated_at.to_datetime
  end

  def update_pdf
    Salaries::PdfJob.perform_later salary_id: self.id
  end

  def has_reference?
    reference.nil? == false
  end

  def init_details_from_reference
    self.is_reference    = false
    self.generic_template = reference.generic_template
    self.married        = reference.married
    self.children_count = reference.children_count
  end

  def init_items
    wage = yearly_salary && yearly_salary_count ? self.yearly_salary / self.yearly_salary_count : 1000.to_money(self.yearly_salary_currency)
    taxes = Salaries::Tax.where(archive: false).all
    item = Salaries::Item.new(title: I18n.t("salary.views.generic_template_item_title"),
                              category: I18n.t("salary.views.generic_template_item_category"),
                              position: 0,
                              value: wage,
                              taxes: taxes)
    self.items << item
  end

  def update_tax_data
    tax_data.each {|t| t.save! } # re-compute value
  end

  def init_items_from_reference
    self.items.destroy_all
    reference.items.each do |item|
      new_item = item.dup
      new_item.salary_id = nil
      new_item.parent_id = item.id
      new_item.tax_ids = item.tax_ids
      self.items << new_item
    end
  end

  def init_tax_data_from_reference
    self.tax_data.destroy_all
    self.tax_data = reference.tax_data.map{|td| td.dup}
  end

  def init_from_reference
    init_details_from_reference
    init_items_from_reference
    init_tax_data_from_reference
  end

  def create_missing_tax_data
    next_pos = tax_data.size
    existing_ids = tax_data.map(&:tax_id)
    Salaries::Tax.where(archive: false).reject{ |t| existing_ids.include?(t.id) }.each do |tax|
      data = tax_data.build(tax: tax, position: next_pos)
      data.reset
      data.save!
      next_pos += 1
    end
  end

  # Salaries::Item call this after_update
  def synchronize_tax_data
    create_missing_tax_data

    tax_data.all.each do |data|
      data.save! # run compute callback
    end
  end

  def year
    from.year # TODO is this always working?
  end

  def interval_in_days
    # date substraction returns fraction
    (to - from).to_i
  end

  def infos
    OpenStruct.new yearly_salary: has_reference? ? reference.yearly_salary : yearly_salary,
                   :married? => married,
                   children_count: children_count,
                   gender: person.gender,
                   age: person.age_at(from.to_date)
  end

  def summary
    h = {}
    h[:taxed_categories] = taxed_categories.as_json
    h[:tax_data] = employee_value_total
    h[:untaxed_categories] = untaxed_categories.as_json
    h[:net_salary] = net_salary
    h
  end

  def taxed_categories
    h = {}
    taxed_items.each do |i|
      h[i.category] ||= 0.to_money
      h[i.category] += i.value
    end
    h.dup
  end

  def untaxed_categories
    h = {}
    untaxed_items.each do |i|
      h[i.category] ||= 0.to_money
      h[i.category] += i.value
    end
    h.dup
  end

  def summary_json
    h = summary
    j = {taxed_categories: {},
         tax_data: 0,
         untaxed_categories: {},
         net_salary: 0 }

    j.each do |cat,val|
      if h[cat].is_a? Hash
        h[cat].each {|k,v| j[cat][k] = v.to_f }
      else
        j[cat] = h[cat].to_f
      end
    end

    j
  end

  def self.interval(from, to)
    raise ArgumentError, "'from' date is missing.".inspect if from.nil?
    raise ArgumentError, "'to' date is missing.".inspect if to.nil?

    where('salaries.from >= ? AND salaries.to <= ? AND is_reference = false', from, to)
  end

  # deductions

  def gross_pay
    taxed_items.reject{|i| i.category.blank? }.map(&:value).sum.to_money
  end

  def net_salary
    gross_pay + untaxed_items_total - employee_value_total
  end

  def employer_value_total
    tax_data.map(&:employer_value).sum.to_money
  end

  def employer_percent_total
    tax_data.map(&:employer_percent).sum
  end

  def employee_value_total
    tax_data.map(&:employee_value).sum.to_money
  end

  def employee_percent_total
    tax_data.map(&:employee_percent).sum
  end

  def tax(name)
    # name could be a regex
    tax_data.joins(:tax).where("salaries_taxes.title ~* ?", name).first
  end

  # elohnausweisssk certificates helpers
  def avs_group
    tax_data.joins(:tax).where("salaries_taxes.exporter_avs_group is true")
  end

  def lpp_group
    tax_data.joins(:tax).where("salaries_taxes.exporter_lpp_group is true")
  end

  def is_group
    tax_data.joins(:tax).where("salaries_taxes.exporter_is_group is true")
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:created_at] = created_at.to_date

    h[:reference_title] = reference.try(:title)

    h[:married] = married?
    h[:yearly_salary]  = yearly_salary.to_f
    h[:children_count] = children_count # number of kids
    h[:salaries_count] = children.count # salaries that use this reference

    h[:gross_pay]           = gross_pay.to_f
    h[:gross_pay_currency]  = gross_pay.currency.try(:iso_code)
    h[:net_salary]          = net_salary.to_f
    h[:net_salary_currency] = net_salary.currency.try(:iso_code)
    h[:person_name]         = person.name

    h[:items] = items.map(&:as_json)
    h[:tax_data] = selected_tax_data.map(&:as_json)


    h[:employer_value_total]   = employer_value_total.to_f
    h[:employer_percent_total] = employer_percent_total.to_f
    h[:employee_value_total]   = employee_value_total.to_f
    h[:employee_percent_total] = employee_percent_total.to_f

    h[:brut_account]      = brut_account
    h[:net_account]       = net_account
    h[:employer_account]  = employer_account

    # PDF generation
    # h[:taxed_items] = taxed_items.as_json
    # h[:untaxed_items] = untaxed_items.as_json
    # h[:selected_tax_data] = selected_tax_data.as_json
    # h[:summary] = summary_json

    h[:errors] = errors
    h
  end

  def yearly_salary
    is_reference ? Money.new(yearly_salary_in_cents, yearly_salary_currency) : reference.yearly_salary
  end

  def yearly_salary_count
    is_reference ? super : reference.yearly_salary_count
  end

  def brut_account
    is_reference ? super : reference.brut_account
  end

  def net_account
    is_reference ? super : reference.net_account
  end

  private

  def ensure_person_have_required_fields
    if person.missing_employee_information.size > 0
      missing_fields = person.missing_employee_information.map do |f|
        I18n.t("activerecord.attributes.person." + f)
      end
      missing_fields = missing_fields.join(", ")

      errors.add(:base,
                  I18n.t('salary.errors.the_required_information_about_this_person_are_not_satisfied',
                    required_fields: missing_fields ))
      false
    end

  end

  def prevent_destroy_active_reference
    children = Salaries::Salary.where(parent_id: self.id)
    if children.size > 0
      errors.add(:base,
                 I18n.t('salary.errors.unable_to_destroy_a_reference_which_has_children_salaries'))
      false
    end
  end

  def ensure_interval_dates_are_for_the_same_year
    if from.year != to.year
      errors.add(:from,
                 I18n.t('salary.errors.from_and_to_dates_should_be_in_the_same_year'))
      errors.add(:to,
                 I18n.t('salary.errors.from_and_to_dates_should_be_in_the_same_year'))
      false
    end
  end

  def ensure_from_date_is_before_to_date
    if from > to
      errors.add(:from,
                 I18n.t('salary.errors.from_date_should_be_before_to_date'))
      errors.add(:to,
                 I18n.t('salary.errors.to_date_should_be_after_from_date'))
      false
    end
  end

  def ensure_taxes_have_data_for_the_given_interval
    taxes_without_data = []
    # NOTE It is not a matter of archive, the selected taxes must have data.
    # selected_tax_data.joins(:tax).where("salaries_taxes.archive is false").map(&:tax).each do |tax|
    selected_tax_data.joins(:tax).map(&:tax).each do |tax|
      # NOTE Salary have to be in the same year, check validation above
      if tax.model.constantize.where(:tax_id => tax.id, :year => to.year).count == 0
        taxes_without_data << tax.title
      end
    end

    unless taxes_without_data.empty?
      errors.add(:base,
                 I18n.t('salary.errors.missing_tax_data_for_the_given_year',
                  :taxes => taxes_without_data.join(", "),
                  :year => to.year))
      false
    end
  end

end
