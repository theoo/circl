
# Mind db:seed in db/seeds.rb
tasks = %w{languages
           private_tags
           public_tags
           application_settings
           roles
           ldap_attributes
           search_attributes
           generic_templates
           task_types
           task_rates}

namespace :db do
  desc "update CIRCL database with all required tasks"
  task :upgrade => [
                    'db:migrate',
                    'db:stored_procedures:load',
  									'db:seed:application_settings:upgrade',
  									'db:seed:search_attributes:upgrade',
  									'db:seed:roles:upgrade',
                    'db:seed:invoice_templates:snapshots:reset',
                    'db:seed:generic_templates:snapshots:reset'
                  ]

  namespace :seed do
    desc "upgrade seeds"
    task :upgrade => :environment do
      tasks.each do |task|
        Rake::Task["db:seed:#{task}:upgrade"].invoke
      end
    end
  end
end

