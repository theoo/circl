class AddCommentFieldToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :comments, :text
  end
end
