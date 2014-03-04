class AddAffairsBids < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :bid_percentage, :float
  end
end
