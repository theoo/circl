class AddAffairsProductsCategoriesOrder < ActiveRecord::Migration
  def change
    create_table :affairs_products_categories do |t|
      t.integer :affair_id, null: false
      t.string  :title
      t.integer :position, null: false
    end

    add_index :affairs_products_categories, :affair_id
    add_index :affairs_products_categories, :position

    add_column :affairs_products_programs, :category_id, :integer
    remove_column :affairs_products_programs, :category

    add_index :affairs_products_programs, :category_id

  end
end
