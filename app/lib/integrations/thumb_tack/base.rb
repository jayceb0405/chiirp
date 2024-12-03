# frozen_string_literal: true

# https://api.thumbtack.com/docs
# https://docs.google.com/document/d/1Mebj0PDnjnHuMi7nIpHC9PJ8mt1LjTPJ9jNQpZnEJ1A

# app/lib/integrations/thumb_tack/base.rb
module Integrations
  module ThumbTack
    class Base
      attr_reader :access_token, :credentials, :error, :faraday_result, :message, :result, :success
      alias success? success

      # initialize ThumbTack
      # tt_client = Integrations::ThumbTack::Base.new()
      #   (req) credentials: (String)
      def initialize(credentials)
        reset_attributes
        @result        = nil
        @credentials   = credentials&.symbolize_keys || {}
        @access_token  = @credentials.dig(:access_token).to_s
        @refresh_token = @credentials.dig(:refresh_token).to_s
        @expires_at    = @credentials.dig(:expires_at) # default expiry is 3600 seconds (1 hour)
      end

      private

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @success        = false
      end

      def update_attributes_from_client(tt_client)
        @error   = tt_client.error
        @message = tt_client.message
        @result  = tt_client.result
        @success = tt_client.success?
      end
    end
  end
end
