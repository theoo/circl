class ChangeAffairsProductsProgramsToProductItems < ActiveRecord::Migration
  def change
    rename_table :affairs_products_programs, :product_items

    # Update rights
    Permission.where(subject: "AffairsProductsProgram").each do |p|
      p.update_attributes subject: "ProductItem"
    end
  end
end
