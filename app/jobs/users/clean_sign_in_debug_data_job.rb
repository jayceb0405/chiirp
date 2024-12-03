# frozen_string_literal: true

# app/jobs/users/clean_sign_in_debug_data_job.rb
module Users
  class CleanSignInDebugDataJob < ApplicationJob
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'clean_sign_in_debug_data').to_s
    end

    # perform the ActiveJob
    def perform(**args)
      Users::SignInDebug.old.destroy_all
    end
  end
end
