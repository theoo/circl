namespace :db do
  namespace :seed do
    namespace :salary_templates do |ns|
      task :create => :environment do
        print "Creating salary_templates:... "
        h = YAML.load_file([Rails.root, 'db/seeds/salaries/salary_templates.yml'].join("/")).first
        file = File.read([Rails.root, "app/assets/javascripts/app/views/settings/salary_templates/template.js.hamlc"].join("/"))
        h['html'] = Haml::Engine.new(file).render
        Salaries::SalaryTemplate.create!(h)
        puts 'done!'
      end

      task :destroy => :environment do
        print "Destroying salary_templates:... "
        h = YAML.load_file([Rails.root, 'db/seeds/salaries/salary_templates.yml'].join("/")).first
        Salaries::SalaryTemplate.where(:title => h['title']).destroy_all
        puts 'done!'
      end

      task :reset => ["seed:salary_templates:destroy", "seed:salary_templates:create"]

      namespace :snapshots do
        desc 'resets salary templates\' snapshots'
        task :reset => :environment do
          Salaries::SalaryTemplate.all.each do |salary_template|
            print "Reseting salary template snapshot for #{salary_template.title}... "
            BackgroundTasks::GenerateSalaryTemplateJpg.process!(:salary_template_id => salary_template.id,
              :person => Person.find(ApplicationSetting.value(:me)))
            puts 'done!'
          end
        end
      end
    end
  end
end
