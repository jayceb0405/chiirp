source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
# Use Puma as the app server
gem 'puma', '~> 6.0'
# gem 'puma', '< 6'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.20'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

##############
# Data Storage
##############
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.4' # https://github.com/ged/ruby-pg
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5.0' # https://github.com/redis/redis-rb
# share connections to Redis
gem 'connection_pool', '~> 2.2' # https://github.com/mperham/connection_pool

gem 'execjs', '~> 2.7'

# use DJ in ActiveRecord / Postgresql
gem 'delayed_job_active_record', '~> 4.1' # https://github.com/collectiveidea/delayed_job_active_record
# Add support for max_attempts, destroy_failed_jobs?, reschedule_at & max_run_time in ActiveJob
gem 'activejob_dj_overrides'

#################
# Logging Support
#################
# Librato monitoring
# gem 'librato-rails', '< 2.0'
# support AppSignal logging
gem 'appsignal', '~> 4'

# use TinyMCE rich text editor
# gem 'tinymce-rails', '~> 6.1'

# use clockwork to start automatic jobs
gem 'clockwork', '~> 3.0' # http://github.com/Rykian/clockwork

# interface to CSV files (required by Ruby 3.4.0+)
gem 'csv', '~> 3.0'

########
# Heroku
########
# support for Heroku metrics
gem 'barnes'
# Ruby HTTP client for the Heroku API
gem 'platform-api'

gem 'jquery-rails', '~> 4.4'

gem 'importmap-rails', '~> 2.0'
gem 'turbo-rails', '~> 2.0'

# telephone parsing / validating / formatting
gem 'phone', '~> 1.2.3'
# email validation
gem 'email_address', '~> 0.2' # https://github.com/afair/email_address

# device identification
gem 'browser', '~> 6.0' # https://github.com/fnando/browser

# pagination helpers
gem 'kaminari', '~> 1.2'

# Expo push notifications SDK
# gem 'exponent-server-sdk', '~> 0.1.0'
# gem 'exponent-server-sdk', git: "https://github.com/aki77/expo-server-sdk-ruby.git", branch: "fix-unknown-error"

# Facebook Business SDK
# gem 'facebookbusiness', '~> 0.3.3.3'
# gem 'facebookbusiness', git: 'https://github.com/jenfi-eng/facebook-ruby-business-sdk'
gem 'koala', '~> 3.0'

# Google APIs
gem 'google-apis-calendar_v3', '~> 0.12'

# Devise authentication
gem 'devise', '~> 4.7'
gem 'devise_invitable', '~> 2.0'
gem 'ginjo-omniauth-slack', require: 'omniauth-slack', git: 'https://github.com/riter-co/omniauth-slack'
gem 'omniauth', '~> 2.0'
gem 'omniauth-facebook', '~> 10.0'
gem 'omniauth-google-oauth2', '~> 1.0'
gem 'omniauth-oauth', '~> 1.1'
gem 'omniauth-oauth2', '~> 1.8'
gem 'omniauth-outreach', git: 'https://github.com/kevinneub/omniauth-outreach'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'rotp', '~> 6.3'

# Starting from 5.5.0 RC1 Doorkeeper requires client authentication for Resource Owner Password Grant
# as stated in the OAuth RFC. You have to create a new OAuth client (Doorkeeper::Application) if you didn't
# have it before and use client credentials in HTTP Basic auth if you previously used this grant flow without
# client authentication.

# To opt out of this you could set the "skip_client_authentication_for_password_grant" configuration option
# to "true", but note that this is in violation of the OAuth spec and represents a security risk.

# Read https://github.com/doorkeeper-gem/doorkeeper/issues/561#issuecomment-612857163 for more details.
gem 'doorkeeper', '~> 5.5'

# Carrierwave / Cloudinary image library
# always load CarrierWave before  Cloudinary
gem 'carrierwave', '~> 2.1'
gem 'cloudinary', '~> 1.18'

# Twilio gems
gem 'sendgrid-ruby', '~> 6.4'
gem 'twilio-ruby', '~> 5.46'

# credit card processing
gem 'authorizenet', '~> 2.0.0'
gem 'stripe', '~> 12.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.9', require: false

# Chronic is a pure Ruby natural language date parser.
gem 'chronic', '~> 0.10.2' # http://injekt.github.com/chronic

# Nokogiri is an XML & HTML parser. https://github.com/sparklemotion/nokogiri
gem 'nokogiri'

# font-awesome
gem 'font-awesome-sass', '~> 6.0'

# Roo implements read access for all common spreadsheet types.
# gem "roo", "~> 2.8.0"
gem 'roo', git: 'https://github.com/roo-rb/roo.git', ref: '868d4ea419cf393c9d8832838d96c82e47116d2f'

# HTTP client library
# gem 'faraday', '~> 1.3.0'
gem 'faraday', '~> 2.0' # https://github.com/lostisland/faraday

# SOAP client library
gem 'savon', '~> 2.0'

# Linguistics provides for number conversion to text
gem 'linguistics', '~> 2.1'

# create graphs & charts.
gem 'chartkick', '~> 5.0' # https://github.com/ankane/chartkick
# group queries by date range
# gem "groupdate"                        # https://github.com/ankane/groupdate

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'debug', '>= 1.0.0', require: 'debug/open_nonstop'
  gem 'erb_lint'                       # https://github.com/Shopify/erb-lint
  gem 'factory_bot_rails', '~> 6.4.0'
  gem 'rubocop-packaging'
  gem 'rubocop-performance'            # https://github.com/rubocop/rubocop-performance
  gem 'rubocop-rails'                  # https://github.com/rubocop/rubocop
  gem 'rubocop-rspec'
  gem 'rubocop-shopify'
  gem 'rubocop-thread_safety'          # https://github.com/rubocop/rubocop-thread_safety
end

group :development do
  gem 'foreman', '~> 0.87' # https://github.com/ddollar/foreman
  gem 'listen', '>= 3.2.1'
  gem 'web-console', '>= 4.1.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring', '~> 4.0'
  # gem 'spring-watcher-listen', '~> 2.0'
  gem 'active_record_doctor', '~> 1.7' # https://github.com/gregnavis/active_record_doctor
  gem 'derailed', '~> 0.1.0' # test using: bundle exec derailed bundle:mem
  gem 'statistics', '~> 1.0' # test using: bundle exec derailed bundle:mem

  # Rails documentation tool
  # gem 'yard'                             # https://github.com/lsegal/yard

  # needed for devo command
  gem 'aws-sdk-ecs', '~> 1.148'
  gem 'commander', '~> 5.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '~> 3.35.3'
  # Easy installation and use of chromedriver to run system tests with Chrome
  # gem 'chromedriver-helper', '~> 2.1.0'
  gem 'capybara', '~> 3.40'
  gem 'database_cleaner-active_record', '~> 2.0'
  gem 'rspec-rails', '~> 7.0'
  gem 'timecop', '~> 0.9'
  gem 'vcr', '~> 6.1'
  gem 'webmock', '~> 3.18'
end

# email template thumbnails
gem 'mini_magick', '~> 4.12'
gem 'selenium-webdriver', '~> 4.13'

# AWS metrics
gem 'aws-sdk-cloudwatch', '~> 1.92'
gem 'statsd-instrument', '~> 3.9'

gem 'jbuilder', '~> 2.13'

gem 'rack-cors', '~> 2.0'
