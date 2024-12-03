# frozen_string_literal: true

# app/jobs/campaigns/destroyed/triggeractions_job.rb
module Campaigns
  module Destroyed
    class TriggeractionsJob < ApplicationJob
      # remove all references to a destroyed Campaign in Triggeraction
      # Campaigns::Destroyed::TriggeractionsJob.perform_now()
      # Campaigns::Destroyed::TriggeractionsJob.set(wait_until: 1.day.from_now).perform_later()
      # Campaigns::Destroyed::TriggeractionsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'triggeraction_references_destroyed').to_s
      end

      # perform the ActiveJob
      #   (req) client_id:   (Integer)
      #   (opt) campaign_id:    (Integer)
      #   (opt) group_id:       (Integer)
      #   (opt) lead_source_id: (Integer)
      #   (opt) stage_id:       (Integer)
      #   (opt) tag_id:         (Integer)
      def perform(**args)
        super

        return if Integer(args.dig(:client_id), exception: false).blank?

        Triggeraction.references_destroyed(**args)
      end
    end
  end
end
