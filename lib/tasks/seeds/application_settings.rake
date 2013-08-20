require 'seed_helper'
SeedHelper::create_tasks_for(:application_settings)

namespace :db do
  namespace :seed do
    namespace :application_settings do |namespace|
      desc "Add missing application settings keys"
      task :upgrade => :environment do
        print "Upgrading application_settings... "
        YAML.load_file("#{Rails.root}/db/seeds/application_settings.yml").each do |h|
          ApplicationSetting.create!(h) unless ApplicationSetting.where(:key => h["key"]).size > 0
        end
        puts 'done!'
      end
    end
  end
end
