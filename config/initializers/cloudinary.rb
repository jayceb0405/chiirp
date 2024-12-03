# frozen_string_literal: true

Cloudinary.config do |config|
  config.cloud_name          = Rails.application.credentials.cloudinary&.cloud_name
  config.api_key             = Rails.application.credentials.cloudinary&.api_key
  config.api_secret          = Rails.application.credentials.cloudinary&.api_secret
  config.secure              = true
  config.enhance_image_tag   = true
  config.static_file_support = true

  if Rails.env.production?
    config.private_cdn         = true
    config.secure_distribution = 'media.chiirp.com'
  end
end
