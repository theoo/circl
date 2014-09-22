class AddNotesToAffair < ActiveRecord::Migration
  def change
    add_column :affairs, :notes, :text
  end
end
