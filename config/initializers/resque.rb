rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'

Resque.redis = Rails.configuration.settings['redis']['environments']
# TODO Ensure Redis (resque) is writing the the correct database (name)