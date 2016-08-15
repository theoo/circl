class CleanupBackgroundTasks < ActiveRecord::Migration
  def change
    Permission.where(subject: "BackgroundTask").destroy_all
  end
end
