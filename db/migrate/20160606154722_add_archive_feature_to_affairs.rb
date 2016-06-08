class AddArchiveFeatureToAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :archive, :boolean, default: false, null: false
    add_column :affairs, :sold_at, :datetime
    add_index :affairs, :archive
    add_index :affairs, :sold_at
  end
end
