class AddValidationTypeToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :type_for_validation, :string, null: false, default: 'string'

    ApplicationSetting.connection.schema_cache.clear!
    ApplicationSetting.reset_column_information

    puts "Updating application settings validation types"
    YAML.load_file("#{Rails.root}/db/seeds/application_settings.yml").each do |i|
      # Without validation
      gc = ApplicationSetting.where(key: i['key']).first
      gc.update_attributes type_for_validation: i['type_for_validation'] if gc
    end

    # Migrate seconds to time
    ApplicationSetting.where(type_for_validation: 'time').each do |gc|
      if gc.value.match(/^\d+$/) and not gc.value.match(/^\d+.(second|minute|hour|day|week|month|year)s?$/)
        gc.update_attributes value: "#{gc.value}.seconds"
      end
    end
  end

  def down
    remove_column :application_settings, :type_for_validation
  end
end
