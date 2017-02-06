class Salaries::TaxData < ApplicationRecord

  #################
  ### CALLBACKS ###
  #################

  before_save :compute

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
  extend  MoneyComposer

  #################
  ### RELATIONS ###
  #################

  belongs_to :salary,
             class_name: 'Salaries::Salary'
  belongs_to :tax,
             class_name: 'Salaries::Tax'

  # money
  money :employer_value
  money :employee_value

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :employee_percent, if: :employee_use_percent
  validates_presence_of :employer_percent, if: :employer_use_percent

  ########################
  ### INSTANCE METHODS ###
  ########################

  def title
    tax.title
  end

  def reference
    salary.reference.tax_data.where(tax_id: tax.id).first
  end

  def children
    salary.children.map{ |s| s.tax_data.where(tax_id: tax.id).first }
  end

  def is_reference?
    salary.is_reference?
  end

  def taxed_items
    tax.items.where(salary_id: salary.id)
  end

  def reference_value
    Money.new(taxed_items.sum(:value_in_cents), salary.yearly_salary.currency)
  end

  def taxed_value
    tax.compute(reference_value, salary.year, salary.infos)[:taxed_value]
  end

  def compute_employer_value_from_percent
    self.employer_value = (reference_value * employer_percent) / 100.0
  end

  def compute_employer_percent_from_value
    if reference_value == 0
      self.employer_percent = 0
    else
      self.employer_percent = (employer_value / reference_value) * 100.0
    end
  end

  def compute_employer
    if employer_use_percent
      compute_employer_value_from_percent
    else
      compute_employer_percent_from_value
    end
  end

  def compute_employee_value_from_percent
    self.employee_value = reference_value * employee_percent / 100.0
  end

  def compute_employee_percent_from_value
    if reference_value == 0
      self.employee_percent = 0
    else
      self.employee_percent = (employee_value / reference_value) * 100.0
    end
  end

  def compute_employee
    if employee_use_percent
      compute_employee_value_from_percent
    else
      compute_employee_percent_from_value
    end
  end

  def compute
    compute_employer
    compute_employee
  end

  def reset
    h = tax.compute(reference_value, salary.year, salary.infos)
    self.employer_value          = h[:employer][:value]
    self.employer_percent        = h[:employer][:percent]
    self.employer_use_percent    = h[:employer][:use_percent]
    self.employee_value          = h[:employee][:value]
    self.employee_percent        = h[:employee][:percent]
    self.employee_use_percent    = h[:employee][:use_percent]
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:tax_title] = tax.title

    h[:reference_value] = reference_value.to_f
    h[:taxed_value] = taxed_value.to_f

    h[:employer_value] = employer_value.to_f
    h[:employee_value] = employee_value.to_f

    h[:errors] = errors
    h
  end

end
