tasks = %w{languages
           private_tags
           public_tags
           application_settings
           query_presets
           jobs
           roles
           locations
           ldap_attributes
           search_attributes
           invoice_templates}

tasks.each do |task|
  Rake::Task["db:seed:#{task}:create"].invoke
end

# Schedule that we need to generate the invoice templates' screenshots
# *after* the server has started, otherwise it cannot serve assets
# needed for the snapshot creation
BackgroundTasks::RunRakeTask.create!(:options => { :name => 'db:seed:invoice_templates:snapshots:reset' })
