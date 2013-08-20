class FixValueInCentsLength < ActiveRecord::Migration
  def change
    change_column :affairs, :value_in_cents, :integer, :limit => 8
    change_column :invoices, :value_in_cents, :integer, :limit => 8, :null => false
    change_column :receipts, :value_in_cents, :integer, :limit => 8

    change_column :salaries_tax_data, :employer_value_in_cents, :integer, :limit => 8
    change_column :salaries_tax_data, :employee_value_in_cents, :integer, :limit => 8

    change_column :salaries_taxes_generic, :salary_from_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_generic, :salary_to_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_generic, :employer_value_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_generic, :employee_value_in_cents, :integer, :limit => 8

    change_column :salaries_taxes_is, :yearly_from_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_is, :yearly_to_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_is, :monthly_from_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_is, :monthly_to_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_is, :hourly_from_in_cents, :integer, :limit => 8
    change_column :salaries_taxes_is, :hourly_to_in_cents, :integer, :limit => 8

    change_column :salaries_items, :value_in_cents, :integer, :limit => 8

    change_column :salaries, :yearly_salary_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_food_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_transport_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_food_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_logding_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_misc_salary_car_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_misc_salary_other_value_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_non_periodic_value_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_capital_value_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_participation_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_compentation_admin_members_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_misc_other_value_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_avs_ac_aanp_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_lpp_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_buy_lpp_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_is_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_alloc_traveling_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_alloc_food_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_alloc_other_actual_cost_value_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_alloc_representation_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_alloc_car_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_alloc_other_fixed_fees_value_in_cents, :integer, :limit => 8
    change_column :salaries, :cert_formation_in_cents, :integer, :limit => 8

    change_column :tasks, :value_in_cents, :integer, :limit => 8
  end
end
