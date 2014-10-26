class AddDimentionsAndWeightToProducts < ActiveRecord::Migration
  def change
    add_column :products, :width, :integer # in mm
    add_column :products, :height, :integer # in mm
    add_column :products, :depth, :integer # in mm
    add_column :products, :volume, :integer # in mm3
    add_column :products, :weight, :integer # in grams
  end
end
