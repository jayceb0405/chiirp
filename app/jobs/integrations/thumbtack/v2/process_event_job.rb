# frozen_string_literal: true

# app/jobs/integrations/thumbtack/v2/process_event_job.rb
module Integrations
  module Thumbtack
    module V2
      class ProcessEventJob < ApplicationJob
        # Integrations::Thumbtack::V2::ProcessEventJob.perform_now()
        # Integrations::Thumbtack::V2::ProcessEventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Thumbtack::V2::ProcessEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'thumbtack_process_event').to_s
        end

        # perform the ActiveJob
        #   (req) client_api_integration_id: (Integer)
        #   (req) webhook_type:              (String) # 'lead', 'lead_update', 'message', 'review'
        #   (req) params:                    (Integer)
        def perform(**args)
          super

          return unless Integer(args.dig(:client_api_integration_id), exception: false).present? &&
                        %w[lead lead_update message review].include?(args.dig(:webhook_type).to_s) && args.dig(:params).present? &&
                        (client_api_integration = ClientApiIntegration.find_by(id: args.dig(:client_api_integration_id).to_i, target: 'thumbtack', name: ''))

          case args[:webhook_type]
          when 'lead'
            Integration::Thumbtack::V2::Base.new(client_api_integration).process_lead_event(params: args[:params])
          when 'lead_update'
            Integration::Thumbtack::V2::Base.new(client_api_integration).process_lead_update_event(params: args[:params])
          when 'message'
            Integration::Thumbtack::V2::Base.new(client_api_integration).process_message_event(params: args[:params])
          when 'review'
            Integration::Thumbtack::V2::Base.new(client_api_integration).process_review_event(params: args[:params])
          end
        end
      end
    end
  end
end
