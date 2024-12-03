# frozen_string_literal: true

# app/jobs/packages/destroy_expired_packages_job.rb
module Packages
  class DestroyExpiredPackagesJob < ApplicationJob
    # Packages::DestroyExpiredPackages.set(wait_until: 1.day.from_now).perform_later()
    # Packages::DestroyExpiredPackages.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    #   (opt) process: (String)

    def initialize(**args)
      super

      @process          = (args.dig(:process).presence || 'destroy_expired_packages').to_s
      @reschedule_secs  = 0
    end

    def perform(**args)
      super

      packages = Package.expired.destroy_all
      package_pages = PackagePage.expired.destroy_all

      JsonLog.info 'DestroyExpiredPackagesJob', { packages: packages.length, package_pages: package_pages.length }
    end
  end
end
