namespace :ldap do

  namespace :create do
    desc 'create configuration'
    task :configuration => :environment do
      raise RuntimeError, "LDAP not configured properly in configuration.yml" unless Rails.configuration.ldap_enabled

      # Create database & ACL
      ldap = Rails.configuration.ldap_config
      dn = "olcDatabase=bdb,cn=config"
      attributes =
      {
        :objectclass    => %w{olcDatabaseConfig olcBdbConfig},
        :olcdatabase    => "bdb",
        :olcdbdirectory => Rails.configuration.settings['ldap']['path'],
        :olcsuffix      => Rails.configuration.settings['ldap']['admin']['base'],
        :olcaccess      => ["to attrs=userPassword
                            by anonymous auth
                            by self read
                            by * none",
                           "to dn.subtree=\"#{Rails.configuration.settings['ldap']['admin']['base']}\"
                            by set.exact=\"this/accessibleBy & user/roles\" read
                            by self read
                            by dn.regex=\"uid=([^,]+),#{Rails.configuration.settings['ldap']['admin']['base']}\" search
                            by anonymous auth
                            by * none"],
        :olcrootdn      => Rails.configuration.settings['ldap']['admin']['auth']['username'],
        :olcrootpw      => Rails.configuration.settings['ldap']['admin']['auth']['password'],
        :olcdbindex     => ['objectClass eq', 'uid pres,eq'],
        :olcsizelimit   => '10000',
      }

      if ldap.add(:dn => dn, :attributes => attributes)
        puts "successfully created configuration"
      else
        puts "Couldn't create configuration: #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
      end
    end

    desc 'create database object'
    task :database => :environment do
      raise RuntimeError, "LDAP not configured properly in configuration.yml" unless Rails.configuration.ldap_enabled

      # Create base object
      ldap = Rails.configuration.ldap_admin
      dn = Rails.configuration.settings['ldap']['admin']['base']
      attributes =
      {
        objectClass: %w{dcObject organization},
        o: 'CIRCL'
      }

      if ldap.add(:dn => dn, :attributes => attributes)
        puts "successfully created '#{dn}'"
      else
        puts "Couldn't create '#{dn}': #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
      end
    end
  end

  desc 'create ldap configuration & database'
  task :create => %w{create:configuration create:database}

  desc 'sync ldap database'
  task :sync => :environment do
    progress = RakeProgressbar.new(Person.count)

    rejected = Person.all.reject do |p|
      success = p.ldap_update
      progress.inc
      success
    end

    progress.finished

    puts "The following people couldn't be synchronized: #{rejected.map(&:id).sort.inspect}"
  end

  desc 'destroy ldap database'
  task :destroy => :environment do
    raise RuntimeError, 'LDAP not configured properly in configuration.yml' unless Rails.configuration.ldap_enabled

    puts 'Destroying ldap entries'
    progress = RakeProgressbar.new(Person.count)
    Person.all.each do |p|
      p.ldap_remove
      progress.inc
    end
    progress.finished

    puts 'It is not currently possible to remove the database.'
    puts "You have to do it manually by doing: rm -r #{Rails.configuration.settings['ldap']['path']}"
    puts 'You also have to edit /etc/ldap/slapd.d/cn=config manually to remove the bdb file etc'
    #ldap = Rails.configuration.ldap_config
    #ldap.delete(:dn => 'olcDatabase={1}bdb,cn=config')
    #if [0, 32].include?(ldap.get_operation_result.code)
    #  puts "successfully destroyed database"
    #else
    #  puts "Couldn't destroy database: #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
    #end
  end
end
