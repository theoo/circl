class ChangeProductItemPositionToFloat < ActiveRecord::Migration
  def change
    change_column :affairs_products_programs, :position, :float
  end
end
