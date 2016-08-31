require 'net/ssh'
require 'net/sftp'

def validate_params(params)
  %i(host loner).each do |i|
    raise ArgumentError, "'#{i}' argument missing" unless params[i]
  end

  defaults = {
    user: 'root',
    port: 22,
    path: '/var/rails/prod',
    backup_dir: '/backups',
    pg_user: 'circl',
    pg_host: 'localhost'
  }

  args = defaults.merge params

  conn = Net::SSH.start(args[:host], args[:user], port: args[:port])
  output = conn.exec!("if test -d #{[args[:path], args[:loner]].join('/')}; then echo '1'; else echo '0'; fi").strip
  if output != '1'
    puts 'Unable to find loner'
    conn.close
    raise ArgumentError, "'loner' attribute is probably be wrong"
  end

  [conn, args]

end

ARGS = [:host, :loner, :port, :user, :path, :backup_dir, :pg_user, :pg_host]

namespace :prod do

  desc "import database from running instance in prod"
  task :import_database, ARGS => :environment do |t, params|

    conn, args = validate_params(params.to_h)
    puts "Connecting using equivalent of 'ssh -p #{args[:port]} #{args[:user]}@#{args[:host]}:#{args[:path]}/#{args[:loner]}'"

    puts "Creating database archive..."
    conn.exec!("pg_dump -U #{args[:pg_user]} -h #{args[:pg_host]} #{args[:loner]} | gzip > #{args[:backup_dir]}/snapshot-#{args[:loner]}.sql.gz")

    Net::SFTP.start(args[:host], args[:user], port: args[:port]) do |ssh|
      puts "Downloading database archive..."
      ssh.download!("#{args[:backup_dir]}/snapshot-#{args[:loner]}.sql.gz",
        [Rails.root, "snapshot-#{args[:loner]}.sql.gz"].join("/"))
    end

    puts "Droping old dev database..."
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke

    puts "Importing a copy of '#{args[:loner]}' database..."
    db_name = Rails.configuration.database_configuration["development"]["database"]

    # Without checking anyth!
    # TODO: backup with pg_dump and restore with pg_restore --no-acl --no-owner
    `gunzip -c #{[Rails.root, "snapshot-#{args[:loner]}.sql.gz"].join("/")} | psql #{db_name}`

    # # TODO import elasticsearch index too

    conn.close
    puts "Loner imported."

  end

  desc "import files to generate templates from running instance in prod"
  task :import_files, ARGS => :environment do |t, params|

    conn, args = validate_params(params.to_h)

    # Fetch local templates
    files = GenericTemplate.all.each_with_object([]) do |t,o|
      o << t.odt.path.match(/#{Rails.root.to_s}(.*)/)[1] unless t.odt.path.nil?
    end

    files += InvoiceTemplate.all.each_with_object([]) do |t,o|
      o << t.odt.path.match(/#{Rails.root.to_s}(.*)/)[1] unless t.odt.path.nil?
    end

    Net::SFTP.start(args[:host], args[:user], port: args[:port]) do |ssh|
      puts "Downloading template files:"
      files.each do |file|
        rel_dir = file.match(/(.*)\/[^\/]+.odt$/)[1]
        dir = [Rails.root, "#{rel_dir}"].join
        unless Dir.exists?(dir)
          puts "Creating directory '#{dir}'"
          FileUtils.mkpath dir
        end

        puts "Downloading #{args[:path]}/#{args[:loner]}#{file} ..."
        ssh.download!("#{args[:path]}/#{args[:loner]}#{file}", [Rails.root, file].join)
      end
    end

    conn.close

  end

  desc "import required date from prod to run it in dev"
  task :import, ARGS => :environment do |t, params|

    include ColorizedOutput

    puts red("THIS IS A DESTRUCTIVE ACTION, LOCAL DEVELOPMENT DATABASE WILL BE ERASED!")
    puts "Type OK if you want to continue."
    print green("Do you dare?: ")
    answer = $stdin.gets.chomp

    if answer == 'OK'
      puts "You said OK. Let's go."
    else
      puts "Bye."
      next
    end

    Rake::Task['prod:import_database'].execute(params)
    Rake::Task['prod:import_files'].execute(params)
  end

end
