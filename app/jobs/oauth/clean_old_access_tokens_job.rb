# frozen_string_literal: true

# app/jobs/oauth/clean_old_access_tokens_job.rb
module Oauth
  class CleanOldAccessTokensJob < ApplicationJob
    # clean out old access tokens
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'access_token_maintenance').to_s
    end

    # delete old access tokens except for Zapier Oauths
    def perform(**args)
      Doorkeeper::AccessToken.where(created_at: ..30.days.ago).where.not(application_id: [5, 6, 7, 8]).destroy_all
    end
  end
end
