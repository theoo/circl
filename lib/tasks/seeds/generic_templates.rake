namespace :db do
  namespace :seed do
    namespace :generic_templates do |ns|
      desc "Create generic templates"
      task :create => :environment do
        print "Creating generic templates:... "
        YAML.load_file([Rails.root, 'db/seeds/generic_templates.yml'].join("/")).each do |h|
          file_path = h.delete('odt')
          gt = GenericTemplate.new(h)
          gt.odt = File.open([Rails.root, file_path].join("/"))
          gt.save!
        end
        puts 'done!'
      end

      desc "Destroy generic templates"
      task :destroy => :environment do
        print "Destroying generic templates:... "
        h = YAML.load_file([Rails.root, 'db/seeds/generic_templates.yml'].join("/")).first
        GenericTemplate.where(:title => h['title']).each{|t|t.destroy}
        puts 'done!'
      end

      desc "Upgrade generic templates"
      task :upgrade => :environment do
        print "Creating generic templates:... "
        YAML.load_file([Rails.root, 'db/seeds/generic_templates.yml'].join("/")).each do |h|
          if GenericTemplate.where(:title => h['title']).count == 0
            file_path = h.delete('odt')
            gt = GenericTemplate.new(h)
            gt.odt = File.open([Rails.root, file_path].join("/"))
            gt.save!
          end
        end
        puts 'done!'
      end

      task :reset => ["seed:generic_templates:destroy", "seed:generic_templates:create"]

      namespace :snapshots do
        desc 'resets salary templates\' snapshots'
        task :reset => :environment do
          GenericTemplate.all.each do |template|
            print "Reseting generic template snapshot for #{template.title}... "
            BackgroundTasks::GenerateGenericTemplateJpg.process!(
              :generic_template_id => template.id,
              :generic_template_title => template.title)
            puts 'done!'
          end
        end
      end
    end
  end
end
