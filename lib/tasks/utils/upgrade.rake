namespace :db do
  desc "update CIRCL database with all required tasks"
  task :upgrade => ['db:migrate',
                    'db:stored_procedures:load',
  									'db:seed:application_settings:upgrade',
  									'db:seed:search_attributes:upgrade',
  									'db:seed:roles:upgrade']
end
