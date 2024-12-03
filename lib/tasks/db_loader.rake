# frozen_string_literal: true

# rails db_loader:update
namespace :db_loader do
  desc 'Add new data to the database'
  task update: :environment do
    key = Digest::SHA256.hexdigest(File.read(__FILE__))
    if DbLoader.exists?(key:)
      Rails.logger.info "Skipping db_loader:update for key: #{key}"
      next
    end

    record = DbLoader.create! key:, last_start_at: Time.current

    ActiveRecord::Base.record_timestamps = false

    # update the database here
    # ideally this should be idempotent

    Client.find_each do |client|
      client.update! dlc10_required: true
    end

    Package.find_each do |package|
      package.update! dlc10_required: true
    end

    ActiveRecord::Base.record_timestamps = true

    record.update! last_stop_at: Time.current
  end
end
