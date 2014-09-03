class AddCachedValueToProductItems < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :value_in_cents, :integer, :null => false, :default => 0
    add_column :affairs_products_programs, :value_currency, :string, :null => false, :default => "CHF"
  end
end
