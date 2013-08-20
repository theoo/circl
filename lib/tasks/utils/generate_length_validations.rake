module LengthValidationGenerator
  def self.string_column_limit(c)
    # TODO test if that works in MySql
    c.sql_type[/character varying\((\d+)\)/, 1]
  end

  def self.generate!
    PermissionsList.list_model_names.sort.each do |model|
      model = model.constantize
      next unless model.ancestors.include?(ActiveRecord::Base)

      puts "\n------------------------------ #{model} ------------------------------\n"

      puts "\n# Validate fields of type 'string' length"
      model.columns.select{ |c| c.type == :string }.each do |c|
        puts "validates_length_of :#{c.name}, :maximum => #{string_column_limit(c)}"
      end

      puts "\n# Validate fields of type 'text' length"
      model.columns.select{ |c| c.type == :text }.each do |c|
        puts "validates_length_of :#{c.name}, :maximum => 65536"
      end
    end
  end
end

namespace :utils do
  desc 'generate & print validates_length_of for each model based on column information'
  task :generate_length_validations => :environment do
    LengthValidationGenerator.generate!
  end
end
