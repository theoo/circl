class AddAffairsBids < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :bid_percentage, :float

    add_column :affairs, :custom_value_with_taxes, :boolean, :default => false
  end
end
