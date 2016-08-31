ENV["RAILS_ENV"] ||= 'test'
require 'rubygems'
require 'spork'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

require 'rake'
load File.expand_path([Rails.root, "/lib/tasks/elasticsearch.rake"].join, __FILE__)
Rake::Task.define_task(:environment)

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
end

Spork.each_run do
  # This code will be run each time you run your specs.
end

ActiveRecord::Migration.maintain_test_schema!

# TODO move this in a helper and include it in the RSpec.configure block?
def generate_length_tests_for(*fields, options)
  describe 'lengths' do
    fields.each do |field|
      if options[:minimum]
        it "should not allow less than #{options[:minimum]} characters in field #{field}" do
          subject.send("#{field}=", 'a' * (options[:minimum] - 1))
          subject.should have_at_least(1).error_on(field)
        end
      end

      if options[:maximum]
        it "should not allow more than #{options[:maximum]} characters in field #{field}" do
          subject.send("#{field}=", 'a' * (options[:maximum] + 1))
          subject.should have_at_least(1).error_on(field)
        end
      end
    end
  end
end

RSpec.configure do |config|

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.include Devise::TestHelpers, type: :controller
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!
  config.render_views = true

  # DatabaseCleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction #
    DatabaseCleaner.clean_with(:truncation, { except: %w(application_settings search_attributes ldap_attributes locations) })
  end

  config.before(:each) do
    # FIXME: should be factories
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Redis fake db
  REDIS_PID = [Rails.root, "tmp/pids/redis-test.pid"].join("/")
  REDIS_CACHE_PATH = [Rails.root, "/tmp/cache/"].join("/")

  config.before(:suite) do
    redis_options = {
      "daemonize"     => 'yes',
      "pidfile"       => REDIS_PID,
      "port"          => 9736,
      "timeout"       => 300,
      "save 900"      => 1,
      "save 300"      => 1,
      "save 60"       => 10000,
      "dbfilename"    => "dump.rdb",
      "dir"           => REDIS_CACHE_PATH,
      "loglevel"      => "debug",
      "logfile"       => "stdout",
      "databases"     => 16
    }.map { |k, v| "--#{k} #{v}" }.join(" ")
    puts `redis-server #{redis_options}`
  end

  config.after(:suite) do
    %x{
      cat "#{REDIS_PID}" | xargs kill -QUIT
      rm -f "#{REDIS_CACHE_PATH}dump.rdb"
    }
  end

end