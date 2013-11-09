module SeedHelper
  def self.create_tasks_for(name)
    namespace :db do
      namespace :seed do
        namespace name do |namespace|
          desc "creates #{name}"
          task :create => :environment do
            print "Creating #{name}... "
            YAML.load_file("#{Rails.root}/db/seeds/#{name}.yml").each do |h|
              name.to_s.singularize.camelize.constantize.create!(h)
            end
            puts 'done!'
          end

          desc "destroys #{name}"
          task :destroy => :environment do
            print "Destroying #{name}... "
            name.to_s.singularize.camelize.constantize.destroy_all
            puts 'done!'
          end

          desc "Add missing application settings keys"
          task :upgrade => :environment do
            print "Upgrading #{name}... "
            YAML.load_file("#{Rails.root}/db/seeds/#{name}.yml").each do |h|
              h.keys.each do |k|
                if name.to_s.singularize.camelize.constantize.where(k.to_sym => h[k]).size == 0
                  name.to_s.singularize.camelize.constantize.create!(h)
                end
              end
            end
            puts 'done!'
          end

          scope = namespace.instance_variable_get('@scope').to_a.join(':')
          desc "resets #{name} (destroys then creates)"
          task :reset => ["#{scope}:destroy", "#{scope}:create"]
        end
      end
    end
  end
end
