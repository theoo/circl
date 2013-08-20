namespace :db do
  namespace :seed do

    desc "add an admin user, require arguments [email, password]"
    task :admin_user, [:email, :password] => :environment do |t, args|
      admin = Person.new  :email => args[:email],
                          :password => args[:password],
                          :roles => Role.all,
                          :main_communication_language =>
                            Language.where(:code => ApplicationSetting.value(:default_locale).to_s.upcase).first

      admin.save!
    end

    desc "generate fake people and data for testing/demo, require [quantity]"
    task :fake_people, [:quantity] => [:environment] do |t, args|

      Rails.configuration.settings['elasticsearch']['enable_index'] = false

      quantity = args[:quantity].to_i
      org_proportion = Random.rand(4)

      @bar = RakeProgressbar.new(quantity)

      # load fake data
      @first = IO.readlines("doc/people_material/gn.txt")
      @last = IO.readlines("doc/people_material/sn.txt")

      # fixtures
      @street = ["Rue", "Avenue", "Boulevard", "Chemin"]
      @num = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      @city = ["Geneve", "Lausanne", "Sion", "Bern", "Biel", "Basel"]

      def add_person(org = false)
        person = Person.new

        if org
          person.organization_name = @first.sample.strip.capitalize
          person.is_an_organization = true
          person.email =  "info@" + person.organization_name + ".net"
        else
          person.first_name = @first.sample.strip.capitalize
          person.last_name = @last.sample.strip.capitalize
          person.email = person.first_name.downcase + "." + person.last_name.downcase + "@" + @first.sample.strip + ".net"
        end

        person.address = @street.sample + " " + @last.sample.strip.capitalize + ", " + (@num.sample+1).to_s + "\n" + @city.sample

        person.main_communication_language = Language.order("RANDOM()").first
        Random.rand(2).times do
          person.communication_languages << Language.order("RANDOM()").first
        end

        person.location = Location.order("RANDOM()").first

        person.private_tags << PrivateTag.order("RANDOM()").first
        Random.rand(3).times do
          person.public_tags << PublicTag.order("RANDOM()").first
        end

        tel = "+41"
        (0..8).each do
          tel += @num.sample.to_s
        end
        person.phone = tel

        # try to add person until validation passes o_O
        if person.valid?
          person.save
          @bar.inc
        else
          add_person
        end

      end

      (1..(quantity - (quantity/10*org_proportion))).each do
        add_person
      end

      (1..(quantity/10*org_proportion)).each do
        add_person(true)
      end

      Rails.configuration.settings['elasticsearch']['enable_index'] = true

      puts "Synchronizing search engine index..."
      Rake::Task['elasticsearch:sync'].invoke


    end

  end
end
