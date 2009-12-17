# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# for debian package : setup proper environment variables and paths
ENV['X_REDMINE_SITEID'] ||= ''
if not ENV['X_REDMINE_SITEID'].empty?
  ENV['RAILS_VH_ETC'] ||= "/opt/redmine/sites/#{ENV['X_REDMINE_SITEID']}/config"
  ENV['RAILS_VH_FILES'] ||= "/opt/redmine/sites/#{ENV['X_REDMINE_SITEID']}/files"
  ENV['RAILS_VH_LOG'] ||= "/opt/redmine/sites/#{ENV['X_REDMINE_SITEID']}/log"
  ENV['RAILS_VH_CACHE'] ||= "/opt/redmine/sites/#{ENV['X_REDMINE_SITEID']}/cache"
  ENV['RAILS_VH_SESSIONS'] ||= "/opt/redmine/sites/#{ENV['X_REDMINE_SITEID']}/sessions"
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
  config.log_path = File.join(ENV['RAILS_VH_LOG'], "#{ENV['RAILS_ENV']}.log") unless !ENV['RAILS_VH_LOG']

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # the file cache store
  config.cache_store = :file_store, ENV['RAILS_VH_CACHE'] unless !ENV['RAILS_VH_CACHE']
  
  # Set Active Record's database.yml path
  config.database_configuration_file = File.join(ENV['RAILS_VH_ETC'], 'database.yml') unless !ENV['RAILS_VH_ETC']
  
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
