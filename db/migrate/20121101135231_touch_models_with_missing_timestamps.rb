class TouchModelsWithMissingTimestamps < ActiveRecord::Migration
  def up
    [Subscription, Permission, BackgroundTask].each do |model|
      model.where(:created_at => nil).update_all(:created_at => Time.now)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
