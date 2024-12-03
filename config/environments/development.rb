require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Prevents against DNS rebinding and other Host header attacks.
  config.hosts = [
    IPAddr.new('0.0.0.0/0'), # All IPv4 addresses.
    IPAddr.new('::/0'),      # All IPv6 addresses.
    'localhost',             # The localhost reserved domain.
    'dev.30secondmortgagequiz.com',
    'dev.30secondroofquiz.com',
    'dev.chrp.site',
    'dev.chrp1.com',
    'dev.chiirp.com',
    'dev.chiirp1.com',
    'dev.chiirp2.co',
    'dev.chiirp3.co',
    'dev.chiirppay.com',
    'dev.chrplink.com',
    'dev.chrpweb.com',
    'dev.homeservicessurvey.com',
    'dev.reptxt1.com',
    'dev.sharesuccessteam.com',
    'dev.solarhomesurvey.com',
    'dev.textt.com',
    %r{.*-dev\.chiirp\.com}
  ]

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Allow my IP address access to the console.
  config.web_console.permissions = ['66.220.0.0/16']

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL', nil) }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local
  config.active_storage.service = :cloudinary

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Respond to errors with format matching request.
  config.debug_exception_response_format = :api

  # Print deprecation notices to the Rails logger.
  # config.active_support.deprecation = :log
  config.active_support.deprecation = :raise

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = false

  # Enable locale fallbacks for I18n.
  # Makes lookups for any locale fall back to the I18n.default_locale when a translation cannot be found.
  # config.i18n.fallbacks = true
  config.i18n.fallbacks = [:en]
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
  config.action_cable.allowed_request_origins = ['https://dev.chiirp.com/', 'https://ian-dev.chiirp.com/', 'https://sylwia-dev.chiirp.com/']

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Set all pages to redirect to SSL.
  config.force_ssl = true
  config.ssl_options = { hsts: { preload: true } }

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
