files = Dir["#{Rails.root}/db/seeds/search_attributes/*.yml"].map{ |f| [File.basename(f, '.yml'), f] }
namespace :db do
  namespace :seed do
    namespace :search_attributes do |namespace|
      scope = namespace.instance_variable_get('@scope').to_a.reverse.join(':')

      files.each do |model, file|
        namespace model do
          task :create => :environment do
            print "Creating search attribute:#{model}... "
            (YAML.load_file(file) || []).each do |h|
              e = SearchAttribute.new
              e.model    = h['model']
              e.name     = h['name']
              e.indexing = h['indexing']
              e.mapping  = h['mapping']
              e.group    = h['group']
              e.save!
            end
            puts 'done!'
          end

          task :destroy => :environment do
            print "Destroying search attribute:#{model}... "
            SearchAttribute.where(:model => model.camelize).destroy_all
            puts 'done!'
          end

          task :reset => ["#{scope}:#{model}:destroy", "#{scope}:#{model}:create"]
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

      %w{create destroy reset}.each do |str|
        desc str
        task str => files.map{ |model, file| "#{scope}:#{model}:#{str}" }
      end
    end
  end
end
