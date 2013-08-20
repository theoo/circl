namespace :elasticsearch do
  desc 'synchronize directory with elasticsearch'
  task :sync => :environment do
    ENV['CLASS'] = 'Person'
    ENV['FORCE'] = 'true'
    Person.mapping
    Rake::Task['tire:import'].invoke
  end
end
