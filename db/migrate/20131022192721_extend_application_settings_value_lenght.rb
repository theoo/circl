class ExtendApplicationSettingsValueLenght < ActiveRecord::Migration
  def up
    change_column :application_settings, :value, :text
  end

  def down
    change_column :application_settings, :value, :string
  end
end
