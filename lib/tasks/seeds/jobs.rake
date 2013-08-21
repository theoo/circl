namespace :db do
  namespace :seed do
    namespace :jobs do |namespace|
      desc 'creates jobs'
      task :create => :environment do
        print 'Creating jobs... '
        values = YAML.load_file("#{Rails.root}/db/seeds/jobs.yml")
        values = values.map{ |h| ActiveRecord::Base.connection.quote(h['name']) }
        ActiveRecord::Base.connection.execute("INSERT INTO jobs (name) VALUES (#{values.join('),(')})")
        puts 'done!'
      end

      desc 'destroys jobs'
      task :destroy => :environment do
        print 'Destroying jobs... '
        ActiveRecord::Base.connection.execute('DELETE FROM jobs')
        puts 'done!'
      end

      scope = namespace.instance_variable_get('@scope').to_a.reverse.join(':')
      desc 'resets jobs'
      task :reset => ["#{scope}:destroy", "#{scope}:create"]
    end
  end
end
