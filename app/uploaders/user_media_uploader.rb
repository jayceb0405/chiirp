# frozen_string_literal: true

class UserMediaUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  # general processing
  process :assign_attributes

  # Provide a default URL as a default if there hasn't been a file uploaded
  def default_url(*args)
    # ActionController::Base.helpers.asset_path([version_name, "tenant/#{I18n.t("tenant.id")}/logo.svg"].compact.join('_'))
  end

  # create a standard version
  version :standard do
    process convert: 'png'
    process resize_to_fit: [400, 400]
  end

  # create a thumbnail version
  version :thumb do
    process eager: true
    process convert: 'png'
    process resize_to_fit: [90, 90]
  end

  # image tag & folder on Cloudinary
  def assign_attributes
    { tags: '', folder: "clients/#{model.user.client_id}/users/#{model.user_id}" }
  end

  # maximum file size
  def size_range
    1..150.megabytes
  end

  # content type white list
  def content_type_allowlist
    UploadableMimeTypes.all_mime_types
  end

  # content type black list
  def content_type_denylist
    ['application/text', 'application/json']
  end

  def public_id
    "#{Cloudinary::PreloadedFile.split_format(original_filename).first}_#{Cloudinary::Utils.random_public_id[0, 6]}"
  end

  protected

  def video?(new_file)
    new_file.content_type.start_with? 'video'
  end
end
