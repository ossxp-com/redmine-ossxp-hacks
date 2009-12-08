# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# for debian package : setup proper environment variables and paths
ENV['X_DEBIAN_SITEID'] ||= ''
if not ENV['X_DEBIAN_SITEID'].nil? and not ENV['X_DEBIAN_SITEID'].none?
  ENV['RAILS_ETC'] ||= "/opt/redmine/sites/#{ENV['X_DEBIAN_SITEID']}/config"
  ENV['RAILS_LOG'] ||= "/opt/redmine/sites/#{ENV['X_DEBIAN_SITEID']}/log"
  ENV['RAILS_VAR'] ||= "/opt/redmine/sites/#{ENV['X_DEBIAN_SITEID']}/var"
  ENV['RAILS_CACHE'] ||= "/opt/redmine/sites/#{ENV['X_DEBIAN_SITEID']}/cache"
end

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Load Engine plugin if available
begin
  require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')
rescue LoadError
  # Not available
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for sweepers
  config.load_paths += %W( #{RAILS_ROOT}/app/sweepers )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store
  config.action_controller.session_store = :PStore

  # log path
  config.log_path = File.join(ENV['RAILS_LOG'], "#{ENV['RAILS_ENV']}.log") unless !ENV['RAILS_LOG']

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # the file cache store
  config.cache_store = :file_store, ENV['RAILS_CACHE'] unless !ENV['RAILS_CACHE']
  
  # Set Active Record's database.yml path
  config.database_configuration_file = File.join(ENV['RAILS_ETC'], 'database.yml') unless !ENV['RAILS_ETC']
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :message_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby
  
  # Deliveries are disabled by default. Do NOT modify this section.
  # Define your email configuration in email.yml instead.
  # It will automatically turn deliveries on
  config.action_mailer.perform_deliveries = false
end
