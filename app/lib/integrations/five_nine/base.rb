# frozen_string_literal: true

# app/lib/integrations/five_nine/base.rb
module Integrations
  module FiveNine
    class Base
      attr_reader :error, :message, :result, :success
      alias success? success

      # initialize Five9
      # f9_client = Integrations::FiveNine::Base.new()
      #   (req) credentials: (String)
      def initialize(credentials)
        reset_attributes
        @result       = nil
        @credentials  = credentials&.symbolize_keys || {}
      end

      def call(method, *args)
        reset_attributes

        f9_client = "Integrations::FiveNine::V#{@credentials&.dig('version').presence || Integration::Five9::Base::CURRENT_VERSION}::Base".constantize.new(@credentials)

        if f9_client.respond_to?(method)
          if args.present?
            f9_client.send(method, args)
          else
            f9_client.send(method)
          end

          update_attributes_from_client(f9_client)
        end

        @result
      end

      private

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @success        = false
      end

      def update_attributes_from_client(f9_client)
        @error   = f9_client.error
        @message = f9_client.message
        @result  = f9_client.result
        @success = f9_client.success?
      end
    end
  end
end
