class AddProductUnits < ActiveRecord::Migration
  def change
    add_column :products, :unit_symbol, :string
    add_column :products, :price_to_unit_rate, :integer
  end
end
