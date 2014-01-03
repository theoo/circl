namespace :db do
  desc "update CIRCL database with all required tasks"
  task :upgrade => ['db:migrate',
                    'db:stored_procedures:load',
  									'db:seed:application_settings:upgrade',
  									'db:seed:search_attributes:upgrade',
  									'db:seed:roles:upgrade',
                    'db:seed:invoice_templates:snapshots:reset',
                    'db:seed:generic_templates:snapshots:reset']
end
