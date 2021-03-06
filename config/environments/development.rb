LinkedDevelopmentApi::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  #config.consider_all_requests_local       = true
  config.consider_all_requests_local = false

  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Pretty print JSON in development mode
  config.middleware.use PrettyJsonResponse

  Tripod.configure do |config|
    config.timeout_seconds = 60
    config.query_endpoint   = 'http://localhost:3030/linkeddev-dev/sparql'
    config.data_endpoint   = 'http://localhost:3030/linkeddev-dev/data'
    # For hacking on rails console
    config.update_endpoint  = 'http://localhost:3030/linkeddev-dev/update'


    #config.query_endpoint = 'http://linked-development-pmd.dev/sparql' #'http://localhost:3030/junk/sparql'
    config.data_endpoint = 'http://localhost:3030/junk/data'
    # For hacking on rails console
    config.update_endpoint = 'http://localhost:3030/junk/update'
  end
end
