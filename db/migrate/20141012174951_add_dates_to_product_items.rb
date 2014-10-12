class AddDatesToProductItems < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :confirmed_at, :datetime, default: nil
    add_column :affairs_products_programs, :delivery_at, :datetime, default: nil
    add_index :affairs_products_programs, :confirmed_at
    add_index :affairs_products_programs, :delivery_at
  end
end
