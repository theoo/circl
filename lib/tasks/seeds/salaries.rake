namespace :db do
  namespace :seed do
    namespace :templates do |ns|
      task :create => :environment do
        print "Creating templates:... "
        h = YAML.load_file([Rails.root, 'db/seeds/salaries/templates.yml'].join("/")).first
        file = File.read([Rails.root, "app/assets/javascripts/app/views/settings/templates/template.js.hamlc"].join("/"))
        h['html'] = Haml::Engine.new(file).render
        Template.create!(h)
        puts 'done!'
      end

      task :destroy => :environment do
        print "Destroying templates:... "
        h = YAML.load_file([Rails.root, 'db/seeds/salaries/templates.yml'].join("/")).first
        Template.where(:title => h['title']).destroy_all
        puts 'done!'
      end

      task :reset => ["seed:templates:destroy", "seed:templates:create"]

      namespace :snapshots do
        desc 'resets salary templates\' snapshots'
        task :reset => :environment do
          Template.all.each do |template|
            print "Reseting salary template snapshot for #{template.title}... "
            BackgroundTasks::GenerateTemplateJpg.process!(:template_id => template.id,
              :person => Person.find(ApplicationSetting.value(:me)))
            puts 'done!'
          end
        end
      end
    end
  end
end
