namespace :test do
  desc "prepare database for rspec testing"
  task :prepare do
    sql_reference = "doc/selenium/circl_test.reference.sql"
    unless File.exists?(sql_reference)
      raise ArgumentError, "#{sql_reference} is missing !"
    end
    Rails.env = 'test'
    db_config = Rails.application.config.database_configuration['test']
    ActiveRecord::Base.establish_connection(db_config)
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    # Not SQL
    # ActiveRecord::Base.connection.execute(IO.read("doc/selenium/circl_test.reference.sql"))
    system("psql -h#{db_config['host']} -U#{db_config['username']} #{db_config['database']} < #{sql_reference} PGPASSWORD=#{db_config['password']}")
    Rake::Task['db:upgrade'].invoke
    ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'])
  end
end
