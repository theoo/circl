class ArchiveTaxes < ActiveRecord::Migration
  def change
    add_column :salaries_taxes, :archive, :boolean, :default => false, :null => false
    add_index :salaries_taxes, :archive
  end
end
