class AddProductItemsCommentAndDates < ActiveRecord::Migration
  def change
    add_column :affairs_products_programs, :comment, :text, default: nil
    add_column :affairs_products_programs, :ordered_at, :datetime, default: nil
    add_index :affairs_products_programs, :ordered_at
  end
end
