namespace :db do
  namespace :stored_procedures do
    desc 'Create or update stored procedures found in db/stored_procedures'
    task :load => :environment do
      Dir.glob([Rails.root, "db", "stored_procedures", "*.sql"].join("/")).each do |file|
        print "Loading " + File.basename(file.to_s) + ": "
        ActiveRecord::Base.connection.execute File.read(file)
        puts "Ok"
      end
    end
  end
end
