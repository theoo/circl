# Mind db:seed:upgrade if the task have if (lib/tasks/utils/upgrade.rake)
tasks = %w{languages
           affairs_conditions
           currencies
           private_tags
           public_tags
           application_settings
           query_presets
           jobs
           roles
           locations
           ldap_attributes
           search_attributes
           salaries_taxes
           generic_templates
           invoice_templates
           task_types
           task_rates}

tasks.each do |task|
  Rake::Task["db:seed:#{task}:create"].invoke
end

# Schedule that we need to generate the invoice templates' screenshots
# *after* the server has started, otherwise it cannot serve assets
# needed for the snapshot creation
RunRakeTask.perform(nil, :name => 'db:stored_procedures:load')
# RunRakeTask.perform(nil, :name => 'db:seed:invoice_templates:snapshots:reset')
# RunRakeTask.create!(nil, :name => 'db:seed:generic_templates:snapshots:reset')
