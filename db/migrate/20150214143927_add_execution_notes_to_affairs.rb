class AddExecutionNotesToAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :execution_notes, :text
  end
end
