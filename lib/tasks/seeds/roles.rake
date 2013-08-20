files = Dir["#{Rails.root}/db/seeds/roles/*.yml"].map{ |f| [File.basename(f, '.yml'), f] }
namespace :db do
  namespace :seed do
    namespace :roles do |namespace|
      scope = namespace.instance_variable_get('@scope').join(':')

      files.each do |role, file|
        namespace role do
          task :create => :environment do
            print "Creating roles:#{role}... "
            r = Role.create!(:name => role)
            (YAML.load_file(file) || []).each do |perm|
              r.permissions.create!(perm)
            end
            puts 'done!'
          end

          task :destroy => :environment do
            print "Destroying roles:#{role}... "
            Role.where(:name => role).destroy_all
            puts 'done!'
          end

          task :reset => ["#{scope}:#{role}:destroy", "#{scope}:#{role}:create"]

          desc "Add missing permissions to existing roles..."
          task :upgrade => :environment do
            print "Add missing permissions to role #{role}... "

            r = Role.where(:name => role)
            if r.size > 0
              r = r.first
              (YAML.load_file(file) || []).each do |perm|
                r.permissions.create!(perm) unless r.permissions.where(perm).count > 0
              end
            else
              raise ArgumentError, "Role #{role} doesn't exist in database, create it first."
            end

            puts 'done!'
          end
        end
      end

      desc 'lists possible subtasks'
      task :list do
        files.sort_by{ |title, file| title }.each do |title, file|
          %w{create destroy reset}.each do |str|
            puts "rake #{scope}:#{title}:#{str}"
          end
        end
      end

      %w{create destroy reset upgrade}.each do |str|
        desc str
        task str => files.map{ |role, file| "#{scope}:#{role}:#{str}" }
      end
    end
  end
end
