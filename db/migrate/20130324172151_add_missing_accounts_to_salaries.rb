class AddMissingAccountsToSalaries < ActiveRecord::Migration
  def change
    rename_column :salaries, :account, :brut_account
    rename_column :salaries, :counterpart_account, :net_account
    add_column :salaries, :employer_account, :string, :default => ''

    rename_column :salaries_taxes, :destination_account, :employee_account
    add_column :salaries_taxes, :employer_account, :string, :default => ''
  end
end
