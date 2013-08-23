namespace :db do
  desc "update CIRCL database with all required tasks"
  task :upgrade => ['db:stored_procedures:load',
  									'db:seed:application_settings:upgrade',
  									'db:seed:roles:upgrade',
  									'db:migrate']
end
