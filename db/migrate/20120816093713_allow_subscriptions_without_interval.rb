class AllowSubscriptionsWithoutInterval < ActiveRecord::Migration
  def up
    change_column   :subscriptions, :interval_starts_on, :date, :null => true
    change_column   :subscriptions, :interval_ends_on, :date, :null => true
  end

  def down
    change_column   :subscriptions, :interval_starts_on, :date, :null => false
    change_column   :subscriptions, :interval_ends_on, :date, :null => false
  end
end
