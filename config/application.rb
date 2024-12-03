require_relative 'boot'

require 'rails/all'
require_relative 'version'

# Require the gems listed in Gemfile, including any gems limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

$stdout.sync = true
$stderr.sync = true

module Funyl
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Configuration for the application, engines, and railties goes here.
    # These settings can be overridden in specific environments using the files in config/environments, which are processed later.

    config.generators do |g|
      # tell Rails generators to use JavaScript and NOT Coffee
      g.javascript_engine = :js

      # create tests with rspec
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'

      g.view_specs false
    end

    # Heroku suggestion to serve static assets
    config.serve_static_assets = true

    # All form_with forms should generate JS/AJAX submissions.
    config.action_view.form_with_generates_remote_forms = true

    # use delayed_job for ActiveJob
    config.active_job.queue_adapter = :delayed_job

    # set SameSite attribute to support cookies in iFrames
    # default = :lax
    # options = :strict, nil
    # excellent StackOverflow article: https://stackoverflow.com/questions/69652408/sessions-of-rails-app-loaded-in-iframe-no-working
    # Rails 7.0.4 guide: https://guides.rubyonrails.org/configuring.html#configuring-action-dispatch
    config.action_dispatch.cookies_same_site_protection = :none

    # do not change the session key without changing config/environments/production.rb:62 as well
    config.session_store :cookie_store, key: '_chiirp_session', expire_after: 2.days

    # handle all exceptions using ExceptionsController via Routes
    config.exceptions_app = self.routes

    # Specify Railties load order.
    # Forces ActiveStorage & ActionMailbox routes to be loaded first.
    # Last route is *path (catch all).
    # https://edgeapi.rubyonrails.org/classes/Rails/Engine.html
    config.railties_order = [ActiveStorage::Engine, ActionMailbox::Engine, :main_app, :all]

    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess, ActionController::Parameters, ActiveSupport::SafeBuffer]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc # Or :local
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    #

    # Define ActionMailer configuration.
    config.action_mailer.preview_paths << Rails.root.join('spec/mailers/previews').to_s
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.default charset: 'utf-8'
    config.action_mailer.perform_caching = false
    config.action_mailer.smtp_settings = {
      user_name:            'apikey',
      password:             Rails.application.credentials.sendgrid&.chiirp,
      domain:               'chiirp.com',
      address:              'smtp.sendgrid.net',
      port:                 587,
      authentication:       :plain,
      enable_starttls_auto: true
    }

    config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
  end
end

module JSON
  def self.is_json?(args)
    JSON.parse(args)
    true
  rescue TypeError
    false
  rescue JSON::ParserError
    false
  end
end
