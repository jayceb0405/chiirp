# frozen_string_literal: true

# remove audio analyzer due to issue with Cloudinary and ActiveStorage checksum
Rails.application.config.active_storage.analyzers = Rails.application.config.active_storage.analyzers - [ActiveStorage::Analyzer::AudioAnalyzer]
