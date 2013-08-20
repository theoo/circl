class AddPaidAttrToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :paid, :boolean, :default => false
    add_index :salaries, :paid
  end
end
