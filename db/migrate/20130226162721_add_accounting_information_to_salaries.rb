class AddAccountingInformationToSalaries < ActiveRecord::Migration
  def change
    add_column  :salaries, :account, :string, :nil => false
    add_column  :salaries, :counterpart_account, :string, :nil => false
  end
end
