class AddCategoryToAffairsProductsProgram < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :category, :string
    add_index :affairs_products_programs, :category
  end
end
