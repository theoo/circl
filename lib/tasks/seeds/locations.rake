# module LocationHelper
#   def self.create_values(values)
#     fields = %w{parent_id name iso_code_a2 iso_code_a3 iso_code_num postal_code_prefix phone_prefix}
#     values.map! do |h|
#       fields.each_with_object([]) do |s, arr|
#         arr << ActiveRecord::Base.connection.quote(h[s.to_sym])
#       end.join(',')
#     end
#     ActiveRecord::Base.connection.execute("INSERT INTO locations (#{fields.join(',')}) VALUES (#{values.join('),(')})")
#   end
# end

# namespace :db do
#   namespace :seed do
#     namespace :locations do |namespace|
#       desc 'creates continents, countries & post codes'
#       task 'create' => :environment do
#         # Continents
#         print 'Creating locations:continents... '
#         root = Location.create!(:name => 'earth')
#         values = YAML.load_file("#{Rails.root}/db/seeds/locations/continents.yml").map do |continent|
#           {
#             :name => continent[:name],
#             :iso_code_a2 => continent[:code],
#             :parent_id => root.id
#           }
#         end
#         LocationHelper::create_values(values)
#         puts 'done!'

#         # Countries
#         print 'Creating locations:countries... '
#         values = CSV.read("#{Rails.root}/db/seeds/locations/countries.csv").map do |row|
#           # id, a2, a3, phone_code, name, continent
#           {
#             :name => row[4],
#             :iso_code_a2 => row[1],
#             :iso_code_a3 => row[2],
#             :iso_code_num => row[0],
#             :phone_prefix => row[3].gsub(/[\s\+]/, ''),
#             :parent_id => Location.where(:name => row[5]).first.id
#           }
#         end
#         LocationHelper::create_values(values)
#         puts 'done!'

#         Dir["#{Rails.root}/db/seeds/locations/post_codes/*.csv"].each do |file|
#           country = File.basename(file, '.csv')
#           print "Creating locations:post_codes:#{country}... "
#           id = Location.where(:name => country.capitalize).first.id
#           values = CSV.read(file).map do |row|
#             {
#               :name => row[1],
#               :postal_code_prefix => row[0],
#               :parent_id => id
#             }
#           end
#           LocationHelper::create_values(values)
#           puts 'done!'
#         end
#       end

#       desc 'destroys continents, countries & post codes'
#       task 'destroy' => :environment do
#         print 'Destroying locations... '
#         ActiveRecord::Base.connection.execute('DELETE FROM locations')
#         puts 'done!'
#       end

#       scope = namespace.instance_variable_get('@scope').to_a.reverse.join(':')
#       desc 'resets continents, countries & post codes'
#       task 'reset' => %w{destroy create}.map{ |s| "#{scope}:#{s}" }
#     end
#   end
# end
