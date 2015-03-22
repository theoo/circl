class AddCreatorIdToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :creator_id, :integer
    add_index  :tasks, :creator_id

    ::Task.all.each do |t|
      t.update_attributes creator_id: t.executer_id
    end

  end
end
