class AddAffairsBids < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :bid_percentage, :float

    add_column :affairs, :custom_value_in_cents, :integer, :null => true
    add_column :affairs, :custom_value_currency, :string, :null => false, :default => 'CHF'
    add_column :affairs, :custom_value_with_taxes, :boolean, :default => false

    add_index :affairs, :custom_value_in_cents
    add_index :affairs, :custom_value_currency
  end
end
