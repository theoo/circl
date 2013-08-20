class UpdateSalaryTables < ActiveRecord::Migration
  def change
  	rename_column :salaries, :is_template, :is_reference
  end
end
