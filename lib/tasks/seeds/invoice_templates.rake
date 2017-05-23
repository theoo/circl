# files = Dir["#{Rails.root}/db/seeds/invoice_templates/*.yml"].map{ |f| [File.basename(f, '.yml'), f] }

# namespace :db do
#   namespace :seed do
#     namespace :invoice_templates do |ns|
#       scope = ns.instance_variable_get('@scope').to_a.reverse.join(':')

#       files.each do |name, file|
#         namespace name do
#           task :create => :environment do
#             print "Creating invoice_templates:#{name}... "
#             h = YAML.load_file(file)
#             InvoiceTemplate.create!(h)
#             puts 'done!'
#           end

#           task :destroy => :environment do
#             print "Destroying invoice_templates:#{name}... "
#             h = YAML.load_file(file)
#             InvoiceTemplate.where(:title => h['title']).destroy_all
#             puts 'done!'
#           end

#           task :reset => ["#{scope}:#{name}:destroy", "#{scope}:#{name}:create"]
#         end
#       end

#       desc 'lists possible subtasks'
#       task :list do
#         files.sort_by{ |title, file| title }.each do |title, file|
#           %w{create destroy reset}.each do |str|
#             puts "rake #{scope}:#{title}:#{str}"
#           end
#         end
#       end

#       %w{create destroy reset}.each do |str|
#         desc str
#         task str => files.map{ |name, file| "#{scope}:#{name}:#{str}" }
#       end

#       namespace :snapshots do
#         desc 'resets invoice templates\' snapshots'
#         task :reset => :environment do
#           InvoiceTemplate.all.each do |invoice_template|
#             print "Reseting invoice template snapshot for #{invoice_template.title}... "
#             Templates::InvoiceThumbnails.perform_now(
#               nil,
#               :invoice_template_id => invoice_template.id,
#               :person => Person.find(ApplicationSetting.value(:me)) )
#             puts 'done!'
#           end
#         end
#       end
#     end
#   end
# end

