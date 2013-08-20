class AddMissingTimestamps < ActiveRecord::Migration
  def change
    add_timestamps :background_tasks
    add_timestamps :permissions
    add_timestamps :subscriptions
  end
end
