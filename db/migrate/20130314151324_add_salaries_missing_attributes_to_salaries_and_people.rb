class AddSalariesMissingAttributesToSalariesAndPeople < ActiveRecord::Migration
  def change
    add_column  :people, :gender, :boolean, :null => true, :default => nil

    add_index :people, :gender

    # elohnausweisssk value groups
    add_column :salaries_taxes, :exporter_avs_group, :boolean, :null => false, :default => false
    add_column :salaries_taxes, :exporter_lpp_group, :boolean, :null => false, :default => false
    add_column :salaries_taxes, :exporter_is_group, :boolean, :null => false, :default => false

    add_index :salaries_taxes, :exporter_avs_group
    add_index :salaries_taxes, :exporter_lpp_group
    add_index :salaries_taxes, :exporter_is_group

    # elohnausweisssk certificates attributes
    add_column :salaries, :cert_transport_in_cents,                     :integer, :null => false, :default => 0
    add_column :salaries, :cert_transport_currency,                     :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_food_in_cents,                          :integer, :null => false, :default => 0
    add_column :salaries, :cert_food_currency,                          :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_logding_in_cents,                       :integer, :null => false, :default => 0
    add_column :salaries, :cert_logding_currency,                       :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_misc_salary_car_in_cents,               :integer, :null => false, :default => 0
    add_column :salaries, :cert_misc_salary_car_currency,               :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_misc_salary_other_title,                :string, :null => false, :default => ''
    add_column :salaries, :cert_misc_salary_other_value_in_cents,       :integer, :null => false, :default => 0
    add_column :salaries, :cert_misc_salary_other_value_currency,       :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_non_periodic_title,                     :string, :null => false, :default => ''
    add_column :salaries, :cert_non_periodic_value_in_cents,            :integer, :null => false, :default => 0
    add_column :salaries, :cert_non_periodic_value_currency,            :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_capital_title,                          :string, :null => false, :default => ''
    add_column :salaries, :cert_capital_value_in_cents,                 :integer, :null => false, :default => 0
    add_column :salaries, :cert_capital_value_currency,                 :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_participation_in_cents,                 :integer, :null => false, :default => 0
    add_column :salaries, :cert_participation_currency,                 :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_compentation_admin_members_in_cents,    :integer, :null => false, :default => 0
    add_column :salaries, :cert_compentation_admin_members_currency,    :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_misc_other_title,                       :string, :null => false, :default => ''
    add_column :salaries, :cert_misc_other_value_in_cents,              :integer, :null => false, :default => 0
    add_column :salaries, :cert_misc_other_value_currency,              :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_avs_ac_aanp_in_cents,                   :integer, :null => false, :default => 0
    add_column :salaries, :cert_avs_ac_aanp_currency,                   :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_lpp_in_cents,                           :integer, :null => false, :default => 0
    add_column :salaries, :cert_lpp_currency,                           :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_buy_lpp_in_cents,                       :integer, :null => false, :default => 0
    add_column :salaries, :cert_buy_lpp_currency,                       :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_is_in_cents,                            :integer, :null => false, :default => 0
    add_column :salaries, :cert_is_currency,                            :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_alloc_traveling_in_cents,               :integer, :null => false, :default => 0
    add_column :salaries, :cert_alloc_traveling_currency,               :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_alloc_food_in_cents,                    :integer, :null => false, :default => 0
    add_column :salaries, :cert_alloc_food_currency,                    :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_alloc_other_actual_cost_title,          :string, :null => false, :default => ''
    add_column :salaries, :cert_alloc_other_actual_cost_value_in_cents, :integer, :null => false, :default => 0
    add_column :salaries, :cert_alloc_other_actual_cost_value_currency, :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_alloc_representation_in_cents,          :integer, :null => false, :default => 0
    add_column :salaries, :cert_alloc_representation_currency,          :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_alloc_car_in_cents,                     :integer, :null => false, :default => 0
    add_column :salaries, :cert_alloc_car_currency,                     :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_alloc_other_fixed_fees_title,           :string, :null => false, :default => ''
    add_column :salaries, :cert_alloc_other_fixed_fees_value_in_cents,  :integer, :null => false, :default => 0
    add_column :salaries, :cert_alloc_other_fixed_fees_value_currency,  :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_formation_in_cents,                     :integer, :null => false, :default => 0
    add_column :salaries, :cert_formation_currency,                     :string, :null => false, :default => 'CHF'
    add_column :salaries, :cert_others_title,                           :string, :null => false, :default => ''
    add_column :salaries, :cert_notes,                                  :text, :null => false, :default => ''
  end
end