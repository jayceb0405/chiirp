# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/send_message_as_note.rb
module Integrations
  module Email
    module V1
      class VerifyDomainsJob < ApplicationJob
        # Integrations::Email::V1::VerifyDomainsJob.perform_later(client_api_integration: @client_api_integration)

        def initialize(**args)
          super

          @process          = (args.dig(:process).presence || 'email_verify_account').to_s
          @reschedule_secs  = 0
        end

        # perform the ActiveJob
        #   (req) client_api_integration: (ClientApiIntegration)
        def perform(**args)
          super

          return if args[:client_api_integration].blank?

          client = Integration::Email::V1::Base.new(args[:client_api_integration])
          client.verify_domain
        end
      end
    end
  end
end
