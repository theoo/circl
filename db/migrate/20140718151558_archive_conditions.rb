class ArchiveConditions < ActiveRecord::Migration
  def change
    add_column :affairs_conditions, :archive, :boolean, default: false, null: false
  end
end
