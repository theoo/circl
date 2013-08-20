class ImproveActivity < ActiveRecord::Migration
  def change
    rename_column :logs, :title, :action
    rename_column :logs, :description, :data
  end
end
