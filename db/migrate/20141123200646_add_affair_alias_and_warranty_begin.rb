class AddAffairAliasAndWarrantyBegin < ActiveRecord::Migration
  def change
    add_column :affairs, :alias_name, :string
    add_index :affairs, :alias_name

    add_column :affairs_products_programs, :warranty_begin, :date
    add_column :affairs_products_programs, :warranty_end, :date
  end
end
