Koala.configure do |config|
  # config.access_token = MY_TOKEN
  # config.app_access_token = MY_APP_ACCESS_TOKEN
  config.app_id = Rails.application.credentials[:facebook][:app_id]
  config.app_secret = Rails.application.credentials[:facebook][:app_secret]
  config.api_version = 'v7.0'
  # See Koala::Configuration for more options, including details on how to send requests through your own proxy servers.
end
