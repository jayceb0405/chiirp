# frozen_string_literal: true

# app/jobs/oauth/revoke_expired_access_tokens_job.rb
module Oauth
  class RevokeExpiredAccessTokensJob < ApplicationJob
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'access_token_maintenance').to_s
    end

    # revoke expired access tokens except for Zapier Oauths
    def perform(**args)
      Doorkeeper::AccessToken.where(created_at: ..48.hours.ago).where(revoked_at: nil).where.not(application_id: [5, 6, 7, 8]).map(&:revoke)
    end
  end
end
