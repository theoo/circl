class SubscriptionReminders < ActiveRecord::Migration
  def up
    add_column :subscriptions, :parent_id, :integer, :allow_nil => true
    add_index :subscriptions, :parent_id
  end

  def down
    remove_column :subscriptions, :parent_id
  end
end
