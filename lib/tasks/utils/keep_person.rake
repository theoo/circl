namespace :utils do
  desc 'keep only one person data in the db (used to restore backups)'
  task :keep_person, [:person_id] => [:environment] do |t, args|
    person_id = args[:person_id].to_i

    puts "WARNING: this will destroy *every data* but the one related to Person(#{person_id})"
    print "Are you sure (y/n)? "
    if STDIN.gets.chomp! == 'y'
      puts 'destroying...'

      # Tables using person_id
      tables_with_person_id = %w{ comments employment_contracts logs people_communication_languages people_private_tags people_public_tags people_roles }
      statements = tables_with_person_id.map{ |table| "delete from #{table} where person_id != #{person_id}" }

      # Tables using foo_id
      statements << "delete from affairs where owner_id != #{person_id}"
      statements << "delete from tasks where executer_id != #{person_id}"

      # Tables with indirect relation, simply delete everything that cannot join to the parent table
      statements << "delete from affairs_subscriptions where affair_id not in (select id from affairs)"
      statements << "delete from invoices where affair_id not in (select id from affairs)"
      statements << "delete from receipts where invoice_id not in (select id from invoices)"

      # Table people
      statements << "delete from people where id != #{person_id}"

      # Tables not related
      tables_unrelated = %w{ application_settings background_tasks invoice_templates jobs languages ldap_attributes locations permissions private_tags public_tags query_presets roles schema_migrations sessions search_attributes subscriptions task_presets task_types }
      statements += tables_unrelated.map{ |table| "delete from #{table}" }

      Person.transaction do
        statements.each do |sql|
          puts sql
          Person.connection.execute(sql)
        end
      end

      puts 'done!'
      puts "run 'pg_dump -a directory | grep -v 'SELECT' > person_#{person_id}.sql' to have a dump of this person"
      puts "run 'psql -f person_#{person_id}.sql directory' to restore this data in another base"
    else
      puts 'aborted'
    end
  end
end
