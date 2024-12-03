# frozen_string_literal: true

class UserAvatarUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  # general processing
  process convert: 'png'
  process :assign_attributes

  # Provide a default URL as a default if there hasn't been a file uploaded
  def default_url(*args)
    ActionController::Base.helpers.asset_path("tenant/#{I18n.t('tenant.id')}/logo.svg")
  end

  version :standard do
    process resize_to_fill: [300, 300, :north]
  end

  # Create different versions of uploaded files
  version :thumb do
    resize_to_fit 90, 90
  end

  version :avatar do
    cloudinary_transformation transformation: [
      { width:   90,
        height:  90,
        crop:    :thumb,
        zoom:    0.75,
        gravity: :face,
        async:   true }
      # :notification_url => "#{I18n.t("tenant.app_protocol")}://#{I18n.t("tenant.#{Rails.env}.app_host")}/cloudinary/callback"
    ]
  end

  # image tag & folder on Cloudinary
  def assign_attributes
    { tags: 'avatar', folder: "clients/#{model.client_id}/users/#{model.id}" }
  end

  # maximum file size
  def size_range
    1..5.megabytes
  end

  # file extension white list
  def extension_whitelist
    %w[jpg jpeg gif png]
  end

  # content type white list
  def content_type_allowlist
    %r{image/}
  end

  # content type black list
  def content_type_denylist
    ['application/text', 'application/json']
  end

  def public_id
    "#{Cloudinary::PreloadedFile.split_format(original_filename).first}_#{Cloudinary::Utils.random_public_id[0, 6]}"
  end
end
