require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'csv'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module CIRCL
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer


    # The default locale is :en and all translations from config/locales/*.yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml').to_s]
    config.i18n.available_locales = [:en, :fr]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = (Rails.env != 'development')

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.autoload_paths += %W(#{config.root}/lib/)
    # config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Precision for bootstrap
    Sass::Script::Number.precision = 8

    # Enable the asset pipeline
    config.assets.enabled = true

    # Precomile all assets
    config.assets.precompile += ['main.css',
      'application.js',
      'i18n.js',
      'i18n/datatables/fr.js',
      'i18n/datatables/en.js' ]

    # SASS
    config.generators.stylesheet_engine = :sass

    # hamlcoffee
    config.hamlcoffee.format = 'html5'

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # TODO put this in the configuration table
    config.time_zone = 'Bern'

    # Setup Devise custom layout for email
    config.to_prepare { Devise::Mailer.layout "mail" }

    # Export javascript translation on reload
    # config.middleware.use I18n::JS::Middleware

    config.active_record.raise_in_transactional_callbacks = true

  end
end
