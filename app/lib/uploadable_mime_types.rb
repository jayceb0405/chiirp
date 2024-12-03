# frozen_string_literal: true

class UploadableMimeTypes
  IMAGE_MIMES       = %w[image/jpeg image/gif image/png image/bmp].freeze
  VIDEO_MIMES       = %w[video/mpeg video/mp4 video/quicktime video/webm video/3gpp video/3gpp2 video/3gpp-tt video/H261 video/H263 video/H263-1998 video/H263-2000 video/H264].freeze
  TEXT_MIMES        = %w[text/vcard text/x-vcard text/csv text/rtf text/richtext text/calendar text/directory].freeze
  APPLICATION_MIMES = %w[application/pdf].freeze
  AUDIO_MIMES       = %w[audio/basic audio/L24 audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio audio/vnd.wave audio/3gpp audio/3gpp2 audio/ac3 audio/vnd.wave audio/webm audio/amr-nb audio/amr].freeze

  # UploadableMimeTypes.all_mime_types
  def self.all_mime_types
    IMAGE_MIMES + VIDEO_MIMES + TEXT_MIMES + APPLICATION_MIMES + AUDIO_MIMES
  end

  def self.image_types
    IMAGE_MIMES
  end

  def self.video_types
    VIDEO_MIMES
  end

  def self.text_types
    TEXT_MIMES
  end

  def self.application_types
    APPLICATION_MIMES
  end

  def self.audio_types
    AUDIO_MIMES
  end

  def self.to_s
    all_mime_types.join(',')
  end
end
