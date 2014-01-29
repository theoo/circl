class FixSalaryYearlySalaryValue < ActiveRecord::Migration
  def change
    add_column :salaries, :yearly_salary_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_items, :value_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_tax_data, :employee_value_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_tax_data, :employer_value_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_generic, :salary_from_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_generic, :salary_to_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_generic, :employer_value_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_generic, :employee_value_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_is, :yearly_from_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_is, :yearly_to_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_is, :monthly_from_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_is, :monthly_to_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_is, :hourly_from_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries_taxes_is, :hourly_to_currency, :string, :null => false, :default => 'CHF'
  end
end
