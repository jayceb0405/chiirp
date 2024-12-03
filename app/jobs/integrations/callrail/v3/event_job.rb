# frozen_string_literal: true

# app/jobs/integrations/callrail/v3/event_job.rb
module Integrations
  module Callrail
    module V3
      class EventJob < ApplicationJob
        # description of this job
        # Integrations::Callrail::V3::EventJob.perform_now()
        # Integrations::Callrail::V3::EventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Callrail::V3::EventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'callrail_process_event').to_s
        end

        # perform the ActiveJob
        # (req) client_api_integration_id:   (Integer)
        # (req) customer_phone_number:       (String)
        # (req) company_id:                  (String)
        # (req) type:                        (String)
        # (req) call_type:                   (String)
        # (opt) direction:                   (String)
        # (req) tracking_phone_number:       (String)
        # (req) lead_status:                 (String)
        # (req) source_name:                 (String)
        # (opt) tags:                        (Array[String])
        # (opt) keywords:                    (Array[String])
        def perform(**args)
          super

          Integration::Callrail::V3::Event.new(args).process
        end
      end
    end
  end
end
