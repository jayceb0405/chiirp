# frozen_string_literal: true

# app/jobs/integrations/slack/post_message_job.rb
module Integrations
  module Slack
    class PostMessageJob < ApplicationJob
      # Integrations::Slack::PostMessageJob.perform_now()
      # Integrations::Slack::PostMessageJob.perform_later()
      # Integrations::Slack::PostMessageJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process         = (args.dig(:process).presence || 'send_slack').to_s
        @reschedule_secs = 0
      end

      # perform the ActiveJob
      #   (req) channel: (String)
      #   (req) content: (String)
      #   (req) token:   (String)
      def perform(**args)
        super

        return if args.dig(:channel).blank? || args.dig(:content).blank? || args.dig(:token).blank?

        Integrations::Slacker::Base.new(args[:token].to_s).post_message(
          channel: args[:channel].to_s,
          content: args[:content].to_s
        )
      end
    end
  end
end
