=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

module SeedHelper
  def self.create_tasks_for(name, options = {})
    defaults = {:except => []}

    options = defaults.merge(options)

    namespace :db do
      namespace :seed do
        namespace name do |namespace|
          if ! options[:except].index(:create)
            desc "creates #{name}"
            task :create => :environment do
              print "Creating #{name}... "
              YAML.load_file("#{Rails.root}/db/seeds/#{name}.yml").each do |h|
                klass = options[:class_name].constantize if options[:class_name]
                klass ||= name.to_s.singularize.camelize.constantize
                klass.create!(h)
              end
              puts 'done!'
            end
          end

          if ! options[:except].index(:destroy)
            desc "destroys #{name}"
            task :destroy => :environment do
              print "Destroying #{name}... "
              klass = options[:class_name].constantize if options[:class_name]
              klass ||= name.to_s.singularize.camelize.constantize
              klass.destroy_all
              puts 'done!'
            end
          end

          if ! options[:except].index(:upgrade)
            desc "Add missing application settings keys"
            task :upgrade => :environment do
              print "Upgrading #{name}... "
              YAML.load_file("#{Rails.root}/db/seeds/#{name}.yml").each do |h|

                klass = options[:class_name].constantize if options[:class_name]
                klass ||= name.to_s.singularize.camelize.constantize

                h.keys.each do |k|
                  if klass.where(k.to_sym => h[k]).size == 0
                    klass.create!(h)
                  end
                end
              end
              puts 'done!'
            end
          end

          scope = namespace.instance_variable_get('@scope').to_a.join(':')

          if ! options[:except].index(:reset)
            desc "resets #{name} (destroys then creates)"
            task :reset => ["#{scope}:destroy", "#{scope}:create"]
          end
        end
      end
    end
  end
end
